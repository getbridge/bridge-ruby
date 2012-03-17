$(function(){

  bridge.getService('chatserver', function(chat){
    chat.join('lobby', {msg: function(name, msg){
      $('#messages').append(name + ': ' + msg + '<br>');
    }}, function(lobby) {
      $('#y').click(function(){
        lobby.msg('someone', $('#x').val());
        $('#x').val('');
      });
    });
  });

});