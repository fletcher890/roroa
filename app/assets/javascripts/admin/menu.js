$(document).ready(function(){

	// nestedSortable function instantiation
	$('ol.sortable').nestedSortable({
		items: 'li',
		maxLevels:3,
		update: function(){
			do_update_function()
		}
	});

	// Save button 
	$('.updateMenu').bind('click', function(e){
		do_update_function()
		do_alert()
	});

	// save the menu to the database
	function do_update_function(){

		// create the data to send through to the server
		var arr = $('ol.sortable').nestedSortable('toArray');
		data = 'data=' + JSON.stringify(arr) + '&menuid=' + $('ol.sortable').attr('data-menuid')
		
		// run ajax call to save the menu data
		$.ajax({
			type: "POST",
			url: '/admin/menus/save_menu',
			data: data,
			dataType: "html",
			success: function(data){
				
			}
		});

	}

	// create a success message when you save the menu
	function do_alert(){
		
		$('#content .container h2').before('<div class="alert alert-success"><button data-dismiss="alert" class="close" type="button">x</button><strong>Success!</strong> Menu was successfully updated.</div>')
		// scroll to the message when created
		$('html,body').animate({
            scrollTop: $("#header").offset().top
        }, 'slow');

	}

	// when clicking the plus/minu icon this will either show or edit the edit div
	$('ol.sortable').on('click', 'i.handler', function(){
		
		container = $(' > .itemInformation', $(this).closest('li'));

		if (container.hasClass('active')){

			// remove the active class and remove the edit div
			$(this).removeClass('icon-minus-sign');
			$(this).addClass('icon-plus-sign');

			container.slideUp('slow');
			container.removeClass('active')

		} else {

			// add active class and show the edit div content
			$(this).removeClass('icon-plus-sign');
			$(this).addClass('icon-minus-sign');

			container.slideDown('slow');
			container.addClass('active')

		}

	})


	$('select.mod').bind('change', function(e){
		form = $(this).closest("form");
		$('input[name="type"]', form).val($(':selected',$(this)).attr('data-type'));
		$('input[name=label]', form).val($(':selected',$(this)).text());
	});

	// creating a menu option 

	$('.span3 form').bind('submit', function(e){
		e.preventDefault();

		// generic variables
		var type = $(this).attr('data-type')
		var data = $(this).serializeArray();
		var dataString = $(this).serialize();

		
		if(data[2]['value'] == ''){
			label = ''
		} else {
			label = data[2]['value']
		}

		// create generic number for id incase names are the same
		var randomnumber = Math.floor(Math.random()*11)
		
		// if the option type is a custom link or an internal link?
		if(type == 'custom'){
			if(($('input[name=customlink]', $(this)).val() != '') && ($('input[name=label]', $(this)).val() != '')){
				html = '<li class="" style="" data-id="option_' + data[1]['value'] + '" id="custom_' + randomnumber + '" data-type="custom" data-data="' + dataString + '"><div>' + label + '<i class="icon-plus-sign pull-right handler"></i></div>'
				$('ol.sortable').append(html);
				build_under_form(data, '#custom_' + randomnumber)
			}
		} else {
			if(($('select[name=linkto]', $(this)).val() != '') && ($('input[name=label]', $(this)).val() != '')){
				formData = $(this).serialize();
				html = '<li class="" style="" data-id="option_' + data[1]['value'] + '" id="' + data[0]['value'] + '_' + randomnumber +'" data-type="' + data[0]['value']  + '" data-data="' + dataString + '"><div>' + label + '<i class="icon-plus-sign pull-right handler"></i></div>'
				$('ol.sortable').append(html);
				build_under_form(data,  '#' +  data[0]['value'] + '_' + randomnumber)
			}
		}

	});
	
	// on save of individual li option - this will serialize the data to the html so when you 
	// save the actual menu it will take this data and send it to the server

	$('ol.sortable').on('click', '.submitForm', function(){
		$(this).closest('li').attr('data-data', $(this).closest('form').serialize())
		$('.updateMenu').trigger('click')
	})


	// $('.span9').on('submit', 'form', function(e){
	// 	e.preventDefault();
	// 	dataString = $(this).serialize();
	// 	parent = $(this).closest('li');
	// 	$(parent).attr('data-data', dataString);
	// 	$('#updateMenu').trigger('click')
	// });	
	
	// remove the option form the list. The form is not updated until you click the update function
	// at which point it serializes the data without the option in.

	$('.span9').on('click', '.deleteOption', function(e){
		e.preventDefault();
		$(this).closest('.itemInformation').slideUp('slow')
		li = $(this).closest('li').fadeOut('slow');
		setTimeout(function(e){
			$(li).remove();
		}, 1000)
	});

	// adding an option to the menu

	function build_under_form(data, selector){			
		$.ajax({
		  type: "POST",
		  url: '/admin/menus/ajax_dropbox',
		  data: data,
		  dataType: "html",
		  success: function(data){
		  	populate(data, selector)
		  }
		});
	}

	// populate the data with the give html through d
	function populate(d, selector){
		$(selector).append(d)
	}

});