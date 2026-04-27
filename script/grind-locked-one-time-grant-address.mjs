#!/usr/bin/env node
import fs from 'fs';
import os from 'os';
import path from 'path';
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { Worker, isMainThread, parentPort, workerData } from 'worker_threads';

const require = createRequire(import.meta.url);
const { defaultAbiCoder } = require('@ethersproject/abi');
const { keccak256 } = require('@ethersproject/keccak256');

const DEFAULT_CREATE2_DEPLOYER = '0x4e59b44847b379578588920ca78fbf26c0b4956c';
const ALLOWED_OPTIONS = new Set(['prefix', 'suffix', 'deployer', 'config', 'artifact', 'salt']);
const CONSTRUCTOR_TYPES = [
  'address',
  'address',
  'address',
  'address',
  'uint64',
  'uint256',
  'uint64',
  'uint256',
  'uint96',
  'uint64',
];

function usage() {
  console.log(`Usage:
  node script/grind-locked-one-time-grant-address.mjs [options]

Options:
  --prefix <hex>          Address prefix after 0x. Defaults to 0000 if no suffix is set.
  --suffix <hex>          Address suffix.
  --deployer <address>    CREATE2 deployer address. Defaults to Foundry's CREATE2 factory.
  --config <path>         Deploy config JSON. Defaults to script/deploy-config.production.json.
  --artifact <path>       LockedOneTimeGrant artifact. Defaults to out/LockedOneTimeGrant.sol/LockedOneTimeGrant.json.
  --salt <bytes32>        Skip grinding and print the address for this exact salt.

Equivalent environment variables:
  PREFIX, SUFFIX, CREATE2_DEPLOYER, DEPLOY_CONFIG_PATH, ARTIFACT_PATH,
  CREATE2_SALT`);
}

function parseArgs(argv) {
  const args = {};

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];

    if (arg === '--help' || arg === '-h') {
      usage();
      process.exit(0);
    }

    if (!arg.startsWith('--')) {
      throw new Error(`Unexpected argument: ${arg}`);
    }

    const [rawKey, inlineValue] = arg.slice(2).split('=', 2);
    const key = rawKey.replace(/-([a-z])/g, (_, char) => char.toUpperCase());

    if (!ALLOWED_OPTIONS.has(key)) {
      throw new Error(`Unknown option: --${rawKey}`);
    }

    const value = inlineValue ?? argv[++i];

    if (value === undefined || value.startsWith('--')) {
      throw new Error(`Missing value for --${rawKey}`);
    }

    args[key] = value;
  }

  return args;
}

function option(args, key, envName, fallback) {
  return args[key] ?? process.env[envName] ?? fallback;
}

function normalizeHexFragment(value, name) {
  const fragment = String(value ?? '')
    .replace(/^0x/i, '')
    .toLowerCase();

  if (!/^[0-9a-f]*$/.test(fragment)) {
    throw new Error(`${name} must be hex`);
  }

  if (fragment.length > 40) {
    throw new Error(`${name} cannot be longer than 40 hex characters`);
  }

  return fragment;
}

function normalizeAddress(value, name) {
  const address = String(value).toLowerCase();

  if (!/^0x[0-9a-f]{40}$/.test(address)) {
    throw new Error(`${name} must be an address`);
  }

  return address;
}

function normalizeBytes32(value, name) {
  const bytes32 = String(value).toLowerCase();

  if (!/^0x[0-9a-f]{64}$/.test(bytes32)) {
    throw new Error(`${name} must be bytes32`);
  }

  return bytes32;
}

function defaultThreadCount() {
  const availableParallelism =
    typeof os.availableParallelism === 'function' ? os.availableParallelism() : os.cpus().length;

  return Math.max(1, availableParallelism);
}

function readConfigField(configText, key) {
  const escapedKey = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = configText.match(new RegExp(`"${escapedKey}"\\s*:\\s*("(?:\\\\.|[^"])*"|\\d+)`));

  if (!match) {
    throw new Error(`Missing ${key} in deploy config`);
  }

  return match[1].startsWith('"') ? JSON.parse(match[1]) : match[1];
}

function loadConstructorValues(configPath) {
  const configText = fs.readFileSync(configPath, 'utf8');

  return [
    normalizeAddress(
      readConfigField(configText, 'worldIDVerifierAddress'),
      'worldIDVerifierAddress'
    ),
    normalizeAddress(readConfigField(configText, 'erc20Address'), 'erc20Address'),
    normalizeAddress(readConfigField(configText, 'holderAddress'), 'holderAddress'),
    normalizeAddress(
      readConfigField(configText, 'allowanceModuleAddress'),
      'allowanceModuleAddress'
    ),
    readConfigField(configText, 'rpId'),
    readConfigField(configText, 'action'),
    readConfigField(configText, 'issuerSchemaId'),
    readConfigField(configText, 'credentialGenesisIssuedAtMin'),
    readConfigField(configText, 'grantAmount'),
    readConfigField(configText, 'lockupPeriod'),
  ];
}

function loadBytecode(artifactPath) {
  if (!fs.existsSync(artifactPath)) {
    throw new Error(`Missing artifact at ${artifactPath}. Run forge build first.`);
  }

  const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
  const bytecode = artifact.bytecode?.object ?? artifact.bytecode;

  if (typeof bytecode !== 'string' || !/^0x[0-9a-fA-F]+$/.test(bytecode) || bytecode === '0x') {
    throw new Error(`Artifact at ${artifactPath} does not contain deploy bytecode`);
  }

  return bytecode;
}

function buildInitCode(artifactPath, configPath) {
  const bytecode = loadBytecode(artifactPath);
  const constructorArgs = defaultAbiCoder.encode(
    CONSTRUCTOR_TYPES,
    loadConstructorValues(configPath)
  );

  return `0x${bytecode.slice(2)}${constructorArgs.slice(2)}`;
}

function create2Prefix(deployer) {
  return `0xff${deployer.slice(2)}`;
}

function computeCreate2Address(prefix, salt, initCodeHash) {
  const digest = keccak256(`${prefix}${salt}${initCodeHash.slice(2)}`);

  return `0x${digest.slice(-40)}`;
}

function saltAt(index) {
  return index.toString(16).padStart(64, '0');
}

function addressMatches(address, prefix, suffix) {
  const body = address.slice(2).toLowerCase();

  return (!prefix || body.startsWith(prefix)) && (!suffix || body.endsWith(suffix));
}

function printResult({
  address,
  salt,
  initCodeHash,
  deployer,
  index,
  attempts,
  prefix,
  suffix,
  threads,
  workerIndex,
}) {
  if (index !== undefined) {
    console.log(`matchedIndex=${index}`);
  }
  if (attempts !== undefined) {
    console.log(threads > 1 ? `matchingWorkerAttempts=${attempts}` : `attempts=${attempts}`);
  }
  if (threads !== undefined) {
    console.log(`threads=${threads}`);
  }
  if (workerIndex !== undefined) {
    console.log(`workerIndex=${workerIndex}`);
  }
  console.log(`address=${address}`);
  console.log(`CREATE2_SALT=${salt}`);
  console.log(`initCodeHash=${initCodeHash}`);
  console.log(`CREATE2_DEPLOYER=${deployer}`);
  console.log(`prefix=${prefix}`);
  console.log(`suffix=${suffix}`);
}

function grindRange({
  create2Prefix,
  initCodeHash,
  prefix,
  suffix,
  startIndex,
  stride,
  workerIndex,
}) {
  let attempts = 0n;

  for (let i = startIndex; ; i += stride) {
    attempts++;

    const salt = saltAt(i);
    const address = computeCreate2Address(create2Prefix, salt, initCodeHash);

    if (addressMatches(address, prefix, suffix)) {
      return {
        found: true,
        address,
        salt: `0x${salt}`,
        index: i,
        attempts,
        workerIndex,
      };
    }
  }

  return { found: false, attempts, workerIndex };
}

async function grindWithWorkers(search, scriptPath) {
  const threadCount = search.threads;

  if (threadCount === 1) {
    const result = grindRange({
      ...search,
      stride: 1n,
      workerIndex: 0,
    });

    if (result.found) {
      return { ...result, threads: threadCount };
    }
  }

  return new Promise((resolve, reject) => {
    let settled = false;
    const workers = [];

    function cleanup() {
      for (const worker of workers) {
        worker.terminate();
      }
    }

    for (let workerIndex = 0; workerIndex < threadCount; workerIndex++) {
      const worker = new Worker(scriptPath, {
        workerData: {
          ...search,
          startIndex: search.startIndex + BigInt(workerIndex),
          stride: BigInt(threadCount),
          workerIndex,
        },
      });

      workers.push(worker);

      worker.on('message', result => {
        if (settled) {
          return;
        }

        if (result.found) {
          settled = true;
          cleanup();
          resolve({ ...result, threads: threadCount });
          return;
        }

        settled = true;
        cleanup();
        reject(new Error('Worker stopped before finding a match'));
      });

      worker.on('error', error => {
        if (settled) {
          return;
        }

        settled = true;
        cleanup();
        reject(error);
      });

      worker.on('exit', code => {
        if (settled || code === 0) {
          return;
        }

        settled = true;
        cleanup();
        reject(new Error(`Worker exited with code ${code}`));
      });
    }
  });
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const scriptPath = fileURLToPath(import.meta.url);
  const root = path.resolve(path.dirname(scriptPath), '..');
  const configPath = path.resolve(
    option(
      args,
      'config',
      'DEPLOY_CONFIG_PATH',
      path.join(root, 'script/deploy-config.production.json')
    )
  );
  const artifactPath = path.resolve(
    option(
      args,
      'artifact',
      'ARTIFACT_PATH',
      path.join(root, 'out/LockedOneTimeGrant.sol/LockedOneTimeGrant.json')
    )
  );
  const deployer = normalizeAddress(
    option(args, 'deployer', 'CREATE2_DEPLOYER', DEFAULT_CREATE2_DEPLOYER),
    'CREATE2_DEPLOYER'
  );
  const explicitSalt = option(args, 'salt', 'CREATE2_SALT');
  const rawPrefix = option(args, 'prefix', 'PREFIX');
  const rawSuffix = option(args, 'suffix', 'SUFFIX');
  const prefix = normalizeHexFragment(
    rawPrefix ?? (rawSuffix === undefined ? '0000' : ''),
    'prefix'
  );
  const suffix = normalizeHexFragment(rawSuffix ?? '', 'suffix');
  const initCodeHash = keccak256(buildInitCode(artifactPath, configPath));
  const create2PreimagePrefix = create2Prefix(deployer);

  if (explicitSalt !== undefined) {
    const salt = normalizeBytes32(explicitSalt, 'CREATE2_SALT');
    const address = computeCreate2Address(create2PreimagePrefix, salt.slice(2), initCodeHash);

    printResult({ address, salt, initCodeHash, deployer, prefix, suffix });
    return;
  }

  const result = await grindWithWorkers(
    {
      create2Prefix: create2PreimagePrefix,
      initCodeHash,
      prefix,
      suffix,
      startIndex: 0n,
      threads: defaultThreadCount(),
    },
    scriptPath
  );

  printResult({
    ...result,
    initCodeHash,
    deployer,
    prefix,
    suffix,
  });
}

function workerMain() {
  parentPort.postMessage(grindRange(workerData));
}

if (isMainThread) {
  main().catch(error => {
    console.error(error instanceof Error ? error.message : error);
    process.exit(1);
  });
} else {
  workerMain();
}
