
function setFocus() {
	if (document.forms.length > 0) {
		var field = document.forms[0];
			for (i=0; i < field.length; i++) {
				if ((field.elements[i].type == "text")
				|| (field.elements[i].type == "textarea")
				|| (field.elements[i].type.toString().charAt(0) == "s")) {
					document.forms[0].elements[i].focus();
					break;
				}
			}
		}
	}
	
	
	
function formatting_tips() {
	if (Element.empty('formatting')) {
		new Ajax.Updater('formatting', '/quickcreatetips.html', {
			method:     'get',
         onFailure:  function() {Element.classNames('formatting').add('failure')},
         onComplete: function() {new Effect.Appear('formatting')}
		});
	} else {
		new Effect[Element.visible('formatting') ? 
		'DropOut' : 'Appear']('formatting');
	}
}



function show_recurrence_weekday() {
	if (document.getElementById) { // DOM3 = IE5, NS6
		document.getElementById('recurrenceweekday').style.display = 'block';
	}
	else {
		if (document.layers) { // Netscape 4
			document.recurrenceweekday.display = 'block';
		}
		else { // IE 4
			document.all.recurrenceweekday.style.display = 'block';
		}
	}
}



function show_recurrence_specific() {
	if (document.getElementById) { // DOM3 = IE5, NS6
		document.getElementById('recurrencespecific').style.display = 'block';
	}
	else {
		if (document.layers) { // Netscape 4
			document.recurrencespecific.display = 'block';
		}
		else { // IE 4
			document.all.recurrencespecific.style.display = 'block';
		}
	}
}


	
function hide_recurrence_weekday() {
	if (document.getElementById) { // DOM3 = IE5, NS6
		document.getElementById('recurrenceweekday').style.display = 'none';
	}
	else {
		if (document.layers) { // Netscape 4
			document.recurrenceweekday.display = 'none';
		}
		else { // IE 4
			document.all.recurrenceweekday.style.display = 'none';
		}
	}
}


	
function hide_recurrence_specific() {
	if (document.getElementById) { // DOM3 = IE5, NS6
		document.getElementById('recurrencespecific').style.display = 'none';
	}
	else {
		if (document.layers) { // Netscape 4
			document.recurrencespecific.display = 'none';
		}
		else { // IE 4
			document.all.recurrencespecific.style.display = 'none';
		}
	}
}




function toggle_recurrence_options() {
	if (document.getElementById) { // DOM3 = IE5, NS6
		if (document.getElementById('recurrence-options').style.display == 'none') {
			document.getElementById('recurrence-options').style.display = 'table-row';
		}
		else {
			document.getElementById('recurrence-options').style.display = 'none';
		}
	}
}



function checkemail() {
	emailfield = document.inviteform.email
	if (!emailfield.value) {
		alert('Please enter an email address');
		return false;
	}
	else if (emailfield.value.indexOf('@') == -1) {
		alert('Please enter a valid email address');
		return false;
	}

	// If the script makes it to here, everything is OK,
	// so you can submit the form

	return true;
}



function SetAllCheckBoxes(FormName, FieldName, CheckValue)
{
	if(!document.forms[FormName])
		return;
	var objCheckBoxes = document.forms[FormName].elements[FieldName];
	if(!objCheckBoxes)
		return;
	var countCheckBoxes = objCheckBoxes.length;
	if(!countCheckBoxes)
		objCheckBoxes.checked = CheckValue;
	else
		// set the check value for all check boxes
		for(var i = 0; i < countCheckBoxes; i++)
			objCheckBoxes[i].checked = CheckValue;
}


function ajaxRating(xml)
{
  var x = xml.responseXML;
  var xmlRating = x.getElementsByTagName('rating');
  var rating = xmlRating[0].firstChild.nodeValue;
}


