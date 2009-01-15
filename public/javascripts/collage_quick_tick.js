Event.addBehavior({
  '.quick_tick:click' : function(e) {
    var span = e.element().up('span');
    new Effect.DropOut(span, {duration:0.8});
    var id = span.id.replace(/\D+/, '');
    new Ajax.Request('/tasks/done/' + id + '?flash=none', {
      asynchronous:true,
      evalScripts:true,
      onFailure:function(request) {
        alert('Apologies, something might have gone wrong. Please refresh your browser to check whether the task was updated properly.');
      }
    });
    e.stop();
  }
});

