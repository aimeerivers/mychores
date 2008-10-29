Ajax.AimeeInPlaceEditor = Class.create();
Object.extend(Ajax.AimeeInPlaceEditor.prototype, Ajax.InPlaceEditor.prototype);
Object.extend(Ajax.AimeeInPlaceEditor.prototype, {


  createEditField: function() {
    // var text = (this.options.loadTextURL ? this.options.loadingText : this.getText());
    
    // Aimee changed this:
    var text;
    if (this.options.loadTextURL) {
      text = this.options.loadingText;
    } else if (this.options.value) {
      text = this.options.value;
    } else {
      text = this.getText();
    }
    
    
    var fld;
    if (1 >= this.options.rows && !/\r|\n/.test(this.getText())) {
      fld = document.createElement('input');
      fld.type = 'text';
      var size = this.options.size || this.options.cols || 0;
      if (0 < size) fld.size = size;
    } else {
      fld = document.createElement('textarea');
      fld.rows = (1 >= this.options.rows ? this.options.autoRows : this.options.rows);
      fld.cols = this.options.cols || 40;
    }
    fld.name = this.options.paramName;
    fld.value = text; // No HTML breaks conversion anymore
    fld.className = 'editor_field';
    if (this.options.submitOnBlur)
      fld.onblur = this._boundSubmitHandler;
    this._controls.editor = fld;
    if (this.options.loadTextURL)
      this.loadExternalText();
    this._form.appendChild(this._controls.editor);
  },
  enterHover: function(e) {
  },
  leaveHover: function(e) {
  }
});

Object.extend(Ajax.AimeeInPlaceEditor.prototype, {
  dispose: Ajax.AimeeInPlaceEditor.prototype.destroy
});

//// Aimee extended the in-place editor for a date editor.
// All it does is overrides the createEditField method
// and provides a getFormattedDate method.

Ajax.AimeeInPlaceDateEditor = Class.create();
Object.extend(Ajax.AimeeInPlaceDateEditor.prototype, Ajax.AimeeInPlaceEditor.prototype);
Object.extend(Ajax.AimeeInPlaceDateEditor.prototype, {
  createEditField: function() {
    var text;
    if(this.options.loadTextURL) {
      text = this.options.loadingText;
    } else if (this.options.year && this.options.month && this.options.day) {
      text = this.getFormattedDate();
    } else {
      text = this.getText();
      text = text.substring(0, text.indexOf("(") - 1);
    }
    
    
    var fld;
    if (1 >= this.options.rows && !/\r|\n/.test(this.getText())) {
      fld = document.createElement('input');
      fld.type = 'text';
      var size = this.options.size || this.options.cols || 0;
      if (0 < size) fld.size = size;
    } else {
      fld = document.createElement('textarea');
      fld.rows = (1 >= this.options.rows ? this.options.autoRows : this.options.rows);
      fld.cols = this.options.cols || 40;
    }
    fld.name = this.options.paramName;
    fld.value = text; // No HTML breaks conversion anymore
    fld.className = 'editor_field';
    if (this.options.submitOnBlur)
      fld.onblur = this._boundSubmitHandler;
    this._controls.editor = fld;
    if (this.options.loadTextURL)
      this.loadExternalText();
    this._form.appendChild(this._controls.editor);
  },
  getFormattedDate: function() {
    var duedate = new Date(this.options.year, this.options.month - 1, this.options.day);
    
    var year_str = String(duedate.getFullYear());
    
    var month = duedate.getMonth() + 1;
    var month_str = String(month);
    if (month < 10) { month_str = "0" + month_str; }
    
    var day = duedate.getDate();
    var day_str = String(day);
    if (day < 10) { day_str = "0" + day_str; }
    
    return year_str + "-" + month_str + "-" + day_str;
  }
});