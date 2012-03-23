var bridge;
$(function(){
  bridge = new Bridge({ host: 'localhost', port: 8091, apiKey: "abcdefgh" }).connect();
});

