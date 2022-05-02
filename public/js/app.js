const App = {
  address: "0x3f6C26A3C5c211BdA3dD61924E057c9977e7f4cD",

  load: async () => {
    console.log('App loading...');

    await App.loadWeb3();
    await App.loadAccount();
    await App.loadContract();

    console.log('App loaded.');
  },

  loadWeb3: async () => {
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      window.alert("Please connect to Metamask.")
    }
    // Modern dapp browsers...
    if (window.ethereum) {
      window.web3 = new Web3(ethereum);
      try {
        // Request account access if needed
        await ethereum.enable();
        // Acccounts now exposed
        web3.eth.sendTransaction({/* ... */});
      } catch (error) {
        // User denied account access...
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = web3.currentProvider;
      window.web3 = new Web3(web3.currentProvider);
      // Acccounts always exposed
      web3.eth.sendTransaction({/* ... */});
    }
    // Non-dapp browsers...
    else {
      console.log('Non-Ethereum browser detected. You should consider trying MetaMask!');
    }
  },

  loadAccount: async () => {
    let accounts = await web3.eth.getAccounts();
    App.account = accounts[0];
    window.ethereum.on('accountsChanged', async () => {
      const newAccounts = await web3.eth.getAccounts();
      App.account = newAccounts[0];
      App.onAccountLoaded();
    });
    App.onAccountLoaded();
  },

  loadContract: async () => {
    const json = await $.getJSON('../contracts/contract.json');
    const contract_abi = new web3.eth.Contract(json, App.address);
    App.contract = contract_abi;
    console.log('Contract loaded.');
  },

  onAccountLoaded: () => {
    console.log('Account loaded:', App.account);
    const btn = document.getElementById('connect-btn');
    btn.innerHTML = 'Wallet Connected';
    btn.disabled = true;
  },

  placeBet: async code => {

    const price_wei = web3.utils.toWei('0.05', 'ether');;
    const tx_params = {
      from: App.account,
      to: App.address,
      value: parseInt(price_wei).toString(16),
      data: App.contract.methods.createBet(code).encodeABI(),
    }

    const feedback_txt = document.getElementById('feedback');

    try {
      const tx_hash = await window.ethereum.request({
        method: "eth_sendTransaction",
        params: [tx_params]
      });

      let transactionFinished = null;
      while (transactionFinished === null) {
        transactionFinished = await web3.eth.getTransactionReceipt(tx_hash);
        if (!transactionFinished) {
          await App.sleep(15000);
        }
      }
      console.log(transactionFinished);

      feedback_txt.innerHTML = '<h2>Your bet has been placed!</h2>';
    } catch (err) {
      console.log('ERROR:', err);
      feedback_txt.innerHTML = '<h2>Your bet could not be placed.</h2>';
    }
    feedback_txt.style.display = 'flex';

  },

  sleep: time => {
    return new Promise(resolve => setTimeout(resolve, time));
  },

}
