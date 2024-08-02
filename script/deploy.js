import fs from 'fs';
import ora from 'ora';
import dotenv from 'dotenv';
import readline from 'readline';
import { Command } from 'commander';
import { execSync } from 'child_process';

const DEFAULT_RPC_URL = 'http://localhost:8545';
const CONFIG_FILENAME = 'script/.deploy-config.json';

const ask = async question => {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise(resolve => {
    rl.question(question, input => {
      resolve(input);
      rl.close();
    });
  });
};

async function loadConfiguration(useConfig) {
  // if (!useConfig) {
  //   return {};
  // }

  let answer = await ask(`Do you want to load configuration from prior runs? [Y/n]: `, 'bool');
  const spinner = ora('Configuration Loading').start();
  if (answer === undefined) {
    answer = true;
  }
  if (answer !== "n" && answer !== "N") {
    if (!fs.existsSync(CONFIG_FILENAME)) {
      spinner.warn('Configuration load requested but no configuration available: continuing');
      return {};
    }
    try {
      const fileContents = JSON.parse(fs.readFileSync(CONFIG_FILENAME).toString());
      if (fileContents) {
        spinner.succeed('Configuration loaded');
        return fileContents;
      } else {
        spinner.warn('Unable to parse configuration: deleting and continuing');
        fs.rmSync(CONFIG_FILENAME);
        return {};
      }
    } catch {
      spinner.warn('Unable to parse configuration: deleting and continuing');
      fs.rmSync(CONFIG_FILENAME);
      return {};
    }
  } else {
    spinner.succeed('Configuration not loaded');
    return {};
  }
}

async function saveConfiguration(config) {
  const oldData = (() => {
    try {
      return JSON.parse(fs.readFileSync(CONFIG_FILENAME).toString());
    } catch {
      return {};
    }
  })();

  const data = JSON.stringify({ ...oldData, ...config }, null, "\t");
  fs.writeFileSync(CONFIG_FILENAME, data);
}

async function isStaging(config) {
  if (config.isStaging === undefined) {
    config.isStaging = process.env.STAGING;
  }
  if (config.isStaging === undefined) {
    config.staging = await ask('Is staging? (y/n) ') === 'y';
  }
}

async function getPrivateKey(config) {
  if (!config.privateKey) {
    config.privateKey = process.env.PRIVATE_KEY;
  }
  if (!config.privateKey) {
    config.privateKey = await ask('Enter deployer private key (0x-prefixed): ');
  }
}

async function getStartMonth(config) {
  if (!config.startMonth) {
    config.startMonth = parseInt(process.env.START_MONTH);
  }
  if (!config.startMonth) {
    config.startMonth = parseInt(await ask('Enter start month: '));
  }
}

async function getStartYear(config) {
  if (!config.startYear) {
    config.startYear = parseInt(process.env.START_YEAR);
  }
  if (!config.startYear) {
    config.startYear = parseInt(await ask('Enter start year: '));
  }
}

async function getAmount(config) {
  if (!config.amount) {
    config.amount = parseInt(process.env.AMOUNT);
  }
  if (!config.amount) {
    config.amount = parseInt(await ask('Enter token amount: '));
  }
}

async function getStartOffset(config) {
  if (!config.startOffset) {
    config.startOffset = parseInt(process.env.START_OFFSET);
  }
  if (!config.startOffset) {
    config.startOffset = parseInt(await ask('Enter start offset: '));
  }
}

async function getHolderPrivateKey(config) {
  if (!config.holderPrivateKey) {
    config.holderPrivateKey = parseInt(process.env.HOLDER_PRIVATE_KEY);
  }
  if (!config.holderPrivateKey) {
    config.holderPrivateKey = parseInt(await ask('Enter your Holder private key: '));
  }
}

async function getApprovalAmount(config) {
  if (!config.approvalAmount) {
    config.approvalAmount = parseInt(process.env.APPROVAL_AMOUNT);
  }
  if (!config.approvalAmount) {
    config.approvalAmount = parseInt(await ask('Enter the amount you want to approve: '));
  }
}

async function getAllowedNullifierHashBlocker(config) {
  if (!config.allowedNullifierHashBlocker) {
    config.allowedNullifierHashBlocker = process.env.ALLOWED_NULLIFIER_HASH_BLOCKER;
  }
  if (!config.allowedNullifierHashBlocker) {
    config.allowedNullifierHashBlocker = await ask('Enter the address of the allowed nullifier hash blocker: ');
  }
}

async function getRecurringGrantDropAddress(config) {
  if (!config.recurringGrantDropAddress) {
    config.recurringGrantDropAddress = process.env.RECURRING_GRANT_DROP_ADDRESS;
  }
  if (!config.recurringGrantDropAddress) {
    config.recurringGrantDropAddress = await ask('Enter the address of the recurring grant drop: ');
  }
}

async function getEthereumRpcUrl(config) {
  if (!config.ethereumRpcUrl) {
    config.ethereumRpcUrl = process.env.ETH_RPC_URL;
  }
  if (!config.ethereumRpcUrl) {
    config.ethereumRpcUrl = await ask(`Enter Ethereum RPC URL: (${DEFAULT_RPC_URL}) `);
  }
  if (!config.ethereumRpcUrl) {
    config.ethereumRpcUrl = DEFAULT_RPC_URL;
  }
}

async function getEtherscanApiKey(config) {
  if (!config.ethereumEtherscanApiKey) {
    config.ethereumEtherscanApiKey = process.env.ETHERSCAN_API_KEY;
  }
  if (!config.ethereumEtherscanApiKey) {
    config.ethereumEtherscanApiKey = await ask(
      `Enter Ethereum Etherscan API KEY: (https://etherscan.io/myaccount) `
    );
  }
}

async function getWorldIDIdentityManagerRouterAddress(config) {
  if (!config.worldIDRouterAddress) {
    config.worldIDRouterAddress = process.env.WORLD_ID_ROUTER_ADDRESS;
  }
  if (!config.worldIDRouterAddress) {
    config.worldIDRouterAddress = await ask('Enter the WorldIDRouter address: ');
  }
}

async function getWorldIDRouterGroupId(config) {
  if (!config.groupId) {
    config.groupId = parseInt(process.env.GROUP_ID);
  }
  if (!config.groupId) {
    config.groupId = parseInt(await ask('Enter WorldIDRouter group id: '));
  }
}

async function getErc20Address(config) {
  if (!config.erc20Address) {
    config.erc20Address = process.env.ERC20_ADDRESS;
  }
  if (!config.erc20Address) {
    config.erc20Address = await ask('Enter ERC20 address: ');
  }
}

async function getHolderAddress(config) {
  if (!config.holderAddress) {
    config.holderAddress = process.env.HOLDER_ADDRESS;
  }
  if (!config.holderAddress) {
    config.holderAddress = await ask('Enter Holder Address: ');
  }
}

async function getSpenderAddress(config) {
  if (!config.spenderAddress) {
    config.spenderAddress = process.env.SPENDER_ADDRESS;
  }
  if (!config.spenderAddress) {
    config.spenderAddress = await ask('Enter Spender Address: ');
  }
}

async function getAirdropParameters(config) {
  await getWorldIDRouterGroupId(config);
  await getErc20Address(config);
  await getHolderAddress(config);
  //await getStartMonth(config);
  //await getStartYear(config);
  //await getAmount(config);
  //await getStartOffset(config);

  await saveConfiguration(config);
}

async function deployAirdrop(config) {
  dotenv.config();

  //await isStaging(config);
  await getPrivateKey(config);
  await getEthereumRpcUrl(config);
  await getEtherscanApiKey(config);
  await getWorldIDIdentityManagerRouterAddress(config);
  await saveConfiguration(config);
  await getAirdropParameters(config);

  const spinner = ora(`Deploying WorldIDAirdrop contract...`).start();

  try {
    const data = execSync(
      `forge script script/RecurringGrantDrop.s.sol:DeployRecurringGrantDrop --fork-url ${config.ethereumRpcUrl} \
      --etherscan-api-key ${config.ethereumEtherscanApiKey} --broadcast --verify -vvvv`
    );
    console.log(data.toString());
    spinner.succeed('Deployed RecurringGrantDrop contract successfully!');
  } catch (err) {
    console.error(err);
    spinner.fail('Deployment of RecurringGrantDrop has failed.');
  }
}

async function deployAirdropReservations(config) {
  dotenv.config();

  //await isStaging(config);
  await getPrivateKey(config);
  await getEthereumRpcUrl(config);
  await getEtherscanApiKey(config);
  await getWorldIDIdentityManagerRouterAddress(config);
  await saveConfiguration(config);
  await getAirdropParameters(config);
  await getRecurringGrantDropAddress(config);

  const spinner = ora(`Deploying RecurringGrantDropReservations contract...`).start();

  try {
    const data = execSync(
      `forge script script/RecurringGrantDropReservations.s.sol:DeployRecurringGrantDropReservations --fork-url ${config.ethereumRpcUrl} \
      --etherscan-api-key ${config.ethereumEtherscanApiKey} --broadcast --verify -vvvv`
    );
    console.log(data.toString());
    spinner.succeed('Deployed RecurringGrantDropReservations contract successfully!');
  } catch (err) {
    console.error(err);
    spinner.fail('Deployment of RecurringGrantDropReservations has failed.');
  }
}

async function deployWLDGrantPreGrant4(config) {
  dotenv.config();

  await getPrivateKey(config);

  const spinner = ora(`Deploying WLDGrantPreGrant4_new contract...`).start();

  try {
    const data = execSync(
      `forge script script/WLDGrantPreGrant4_new.s.sol:DeployWLDGrantPreGrant4_new --fork-url ${config.ethereumRpcUrl} \
      --etherscan-api-key ${config.ethereumEtherscanApiKey} --broadcast --verify -vvvv`
    );
    console.log(data.toString());
    spinner.succeed('Deployed WLDGrantPreGrant4_new contract successfully!');
  } catch (err) {
    console.error(err);
    spinner.fail('Deployment of WLDGrantPreGrant4_new has failed.');
  }
}

async function setAllowanceMax(config) {
  await getErc20Address(config);
  await getSpenderAddress(config);
  await getHolderPrivateKey(config);

  await saveConfiguration(config);

  const spinner = ora(`setting allowance...`).start();

  try {
    const data = execSync(
      `forge script script/utils/SetAllowanceERC20_max.s.sol:SetAllowanceERC20Max --fork-url ${config.ethereumRpcUrl} \
      --broadcast -vvvv`
    );
    console.log(data.toString());

    spinner.succeed(`Allowance set for ${config.holderAddress}!`);
  } catch (err) {
    console.error(err);
    spinner.fail(`Setting allowance for ${config.holderAddress} failed.`);
  }
}

async function setAllowance(config) {
  await getErc20Address(config);
  await getSpenderAddress(config);
  await getHolderPrivateKey(config);
  await getApprovalAmount(config);

  await saveConfiguration(config);

  const spinner = ora(`setting allowance...`).start();

  try {
    const data = execSync(
      `forge script script/utils/SetAllowanceERC20.s.sol:SetAllowanceERC20 --fork-url ${config.ethereumRpcUrl} \
      --broadcast -vvvv`
    );
    console.log(data.toString());

    spinner.succeed(`Allowance set for ${config.holderAddress}!`);
  } catch (err) {
    console.error(err);
    spinner.fail(`Setting allowance for ${config.holderAddress} failed.`);
  }
}

async function addAllowedNullifierHashBlocker(config) {
  await getPrivateKey(config);
  await getAllowedNullifierHashBlocker(config);
  await getRecurringGrantDropAddress(config);

  await saveConfiguration(config);

  const spinner = ora(`Adding allowed nullifier hash blocker...`).start();

  try {
    const data = execSync(
      `forge script script/utils/AddAllowedNullifierHashBlocker.s.sol:AddAllowedNullifierHashBlocker --fork-url ${config.ethereumRpcUrl} \
      --broadcast -vvvv`
    );
    console.log(data.toString());

    spinner.succeed(`Allowed nullifier hash blocker set for ${config.recurringGrantDropAddress}!`);
  } catch (err) {
    console.error(err);
    spinner.fail(`Adding allowed nullifier hash blocker for ${config.recurringGrantDropAddress} failed.`);
  }
}

async function main() {
  const program = new Command();

  program
    .name('deploy-airdrop')
    .command('deploy-airdrop')
    .description('Interactively deploys the RecurringGrantDrop contracts.')
    .action(async () => {
      const options = program.opts();
      let config = await loadConfiguration(options.config);
      delete config.staging; // allows get asked for this one
      await deployAirdropReservations(config);
      await saveConfiguration(config);
    });

    program
    .name('deploy-airdrop-reservations')
    .command('deploy-airdrop-reservations')
    .description('Interactively deploys the RecurringGrantDropReservations contracts.')
    .action(async () => {
      const options = program.opts();
      let config = await loadConfiguration(options.config);
      delete config.staging; // allows get asked for this one
      await deployAirdrop(config);
      await saveConfiguration(config);
    });

  program
    .name('set-allowance-max')
    .command('set-allowance-max')
    .description('Sets ERC20 token allowance of the holder address to the max amount.')
    .action(async () => {
      const options = program.opts();
      let config = await loadConfiguration(options.config);
      await setAllowanceMax(config);
      await saveConfiguration(config);
    });

  program
    .name('set-allowance')
    .command('set-allowance')
    .description('Sets ERC20 token allowance of the holder address to the specified amount.')
    .action(async () => {
      const options = program.opts();
      let config = await loadConfiguration(options.config);
      await setAllowance(config);
      await saveConfiguration(config);
    });

  program
    .name('add-allowed-nullifier-hash-blocker')
    .command('add-allowed-nullifier-hash-blocker')
    .description('Adds an allowed nullifier hash blocker to the RecurringGrantDrop contract.')
    .action(async () => {
      const options = program.opts();
      let config = await loadConfiguration(options.config);
      await addAllowedNullifierHashBlocker(config);
      await saveConfiguration(config);
    });

  program
    .name('deploy-wld-grant-pre-grant-4-new')
    .command('deploy-wld-grant-pre-grant-4-new')
    .description('Deploys the WLDGrantPreGrant4_new contract')
    .action(async () => {
      const options = program.opts();
      let config = await loadConfiguration(options.config);
      await deployWLDGrantPreGrant4(config);
      await saveConfiguration(config);
    });

  await program.parseAsync();
}

main().then(() => process.exit(0));
