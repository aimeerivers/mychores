Event.addBehavior({
  '.quick_tick:click' : function(e) {
    var row = e.element().up('tr');
    new Effect.Highlight(row);
    new Effect.Fade(row, {duration:0.8});
    var id = row.id.replace(/\D+/, '');
    new Ajax.Request('/tasks/done/' + id + '?flash=none', {
      asynchronous:true,
      evalScripts:true,
      onFailure:function(request) {
        alert('Apologies, something might have gone wrong. Please refresh your browser to check whether the task was updated properly.');
      }
    });
    e.stop();
  },
  
  '.quick_skip:click' : function(e) {
    var row = e.element().up('tr');
    new Effect.Pulsate(row, {duration:0.4, pulses:2, from:0.7});
    new Effect.SwitchOff(row);
    var id = row.id.replace(/\D+/, '');
    new Ajax.Request('/tasks/skip/' + id + '?flash=none', {
      asynchronous:true,
      evalScripts:true,
      onFailure:function(request) {
        alert('Apologies, something might have gone wrong. Please refresh your browser to check whether the task was updated properly.');
      }
    });
    e.stop();
  }
});

