/**
 * Dynamic Rating stars
 * @copyright 2006 Beau D. Scott http://beauscott.com
 * @
 */

var Stars = Class.create();
Stars.prototype = {
	/**
	 * Mouse X position
	 * @var {Number} options
	 */
	_x: 0,
	/**
	 * Mouse X position
	 * @var {Number} options
	 */
	_y: 0,
	/**
	 * Constructor
	 * @param {Object} options
	 */
	initialize: function(options)
	{

		/**
		 * Initialized?
		 * @var (Boolean)
		 */
		this._initialized = false;

		/**
		 * Base option values
		 * @var (Object)
		 */
		this.options = {
			bindField: null,			// Form Field to bind the value to
			maxRating: 5,				// Maximum rating, determines number of stars
			container: null,			// Container of stars
			imagePath: 'images/',		// Path to star images
			callback: null,				// Callback function, fires when the stars are clicked
			actionURL: null,			// URL to call when clicked. The rating will be appended to the end of the URL (eg: /rate.php?id=5&rating=)
			value: 0,					// Initial Value
			locked: false
		};
		Object.extend(this.options, options);
		this.locked = this.options.locked ? true : false;
		/**
		 * Image sources for hover and user-set state ratings
		 */
		this._starSrc = {
			empty: this.options.imagePath + "emptystar.png",
			full: this.options.imagePath + "yellowstar.png",
			half: this.options.imagePath + "star-half.gif"
		};
		/**
		 * Preload images
		 */
		for(var x in this._starSrc)
		{
			var y = new Image();
			y.src = this._starSrc[x];
		}

		document.getElem

		/**
		 * Images to show for pre-set values, changes when hovered, if not locked.
		 */
		this._setStarSrc = {
			empty: this.options.imagePath + "emptystar.png",
			full: this.options.imagePath + "yellowstar.png",
			half: this.options.imagePath + "star-ps-half.gif"
		};

		/**
		 * Preload images
		 */
		for(var x in this._setStarSrc)
		{
			var y = new Image();
			y.src = this._setStarSrc[x];
		}

		this.value = -1;
		this.stars = [];
		this._clicked = false;


		if(this.options.container)
		{
			this._container = $(this.options.container);
			this.id = this._container.id;
		}
		else
		{
			this.id = 'starsContainer.' + Math.random(0, 100000);
			document.write('<span id="' + this.id + '"></span>');
			this._container = $(this.id);
		}
		this._display();
		this.setValue(this.options.value);
		this._initialized = true;
	},
	_display: function()
	{
		for(var i = 0; i < this.options.maxRating; i++)
		{
			var star = new Image();
			star.src = this.locked ? this._starSrc.empty : this._setStarSrc.empty;
			star.style.cursor = 'pointer';
			
			var importance_text = null;
			switch(i + 1) {
			     case 1: importance_text = 'trivial'; break;
			     case 2: importance_text = 'unimportant'; break;
			     case 3: importance_text = 'non-essential'; break;
			     case 4: importance_text = 'normal'; break;
			     case 5: importance_text = 'significant'; break;
			     case 6: importance_text = 'important'; break;
			     case 7: importance_text = 'critical'; break;
			     default: importance_text = 'unknown'
			}
			
			star.title = (i + 1) + ': ' + importance_text;
			
			!this.locked && Event.observe(star, 'mouseover', this._starHover.bind(this));
			!this.locked && Event.observe(star, 'click', this._starClick.bind(this));
			!this.locked && Event.observe(star, 'mouseout', this._starClear.bind(this));
			this.stars.push(star);
			this._container.appendChild(star);
		}
	},
	_starHover: function(e)
	{
		if(this.locked) return;
		if(!e) e = window.event;
		var star = Event.element(e);

		var greater = false;
		for(var i = 0; i < this.stars.length; i++)
		{
			this.stars[i].src = greater ? this._starSrc.empty : this._starSrc.full;
			if(this.stars[i] == star) greater = true;
		}
	},
	_starClick: function(e)
	{
		if(this.locked) return;
		if(!e) e = window.event;
		var star = Event.element(e);
		this._clicked = true;
		for(var i = 0; i < this.stars.length; i++)
		{
			if(this.stars[i] == star)
			{
				this.setValue(i+1);
				break;
			}
		}
	},
	_starClear: function(e)
	{
		if(this.locked && this._initialized) return;
		var greater = false;
		for(var i = 0; i < this.stars.length; i++)
		{
			if(i > this.value) greater = true;
			if((this._initialized && this._clicked) || this.value == -1)
				this.stars[i].src = greater ? (this.value + .5 == i) ? this._starSrc.half : this._starSrc.empty : this._starSrc.full;
			else
				this.stars[i].src = greater ? (this.value + .5 == i) ? this._setStarSrc.half : this._setStarSrc.empty : this._setStarSrc.full;
		}
	},
	/**
	 * Sets the value of the star object, redraws the UI
	 * @param {Number} value to set
	 * @param {Boolean} optional, do the callback function, default true
	 */
	setValue: function(val)
	{
		var doCallBack = arguments.length > 1 ? !!arguments[1] : true;
		if(this.locked && this._initialized) return;
		this.value = val-1; //0-based
		if(this.options.bindField)
			$(this.options.bindField).value = val;
		if(this._initialized && doCallBack)
		{
			if(this.options.actionURL)
				new Ajax.Request(this.options.actionURL + val, {onComplete: this.options['callback'], method: 'get'});
			else
				if(this.options.callback)
					this.options['callback'](val);
		}
		this._starClear();
	}
};