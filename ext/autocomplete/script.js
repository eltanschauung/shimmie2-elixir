function initTagAutocomplete() {
	var metatags = ['order:id', 'order:width', 'order:height', 'order:filesize', 'order:filename', 'order:favorites'];
	var searchFields = $('[name="search"].autocomplete_tags').not('.tagit-hidden-field');

	searchFields.each(function () {
		var $field = $(this);
		if ($field.data('tagit-initialized')) return;
		$field.data('tagit-initialized', true);
		var fieldPlaceholder = $field.attr('placeholder') || '';

		$field.tagit({
			singleFieldDelimiter: ' ',
			placeholderText: fieldPlaceholder,
			beforeTagAdded: function(event, ui) {
				if(metatags.indexOf(ui.tagLabel) !== -1) {
					ui.tag.addClass('tag-metatag');
				} else if (ui.tagLabel && ui.tagLabel[0] === '-') {
					ui.tag.addClass('tag-negative');
				} else {
					ui.tag.addClass('tag-positive');
				}
			},
			autocomplete : ({
				source: function (request, response) {
					var ac_metatags = $.map(
						$.grep(metatags, function(s) {
							// Only show metatags for strings longer than one character
							return (request.term.length > 1 && s.indexOf(request.term) === 0);
						}),
						function(item) {
							return {
								label : item + ' [metatag]',
								value : item
							};
						}
					);

					var isNegative = (request.term[0] === '-');
					$.ajax({
						url: base_href + '/api/internal/autocomplete',
						data: {'s': (isNegative ? request.term.substring(1) : request.term)},
						dataType : 'json',
						type : 'GET',
						success : function (data) {
							response(
								$.merge(ac_metatags,
									$.map(data, function (count, item) {
										item = (isNegative ? '-'+item : item);
										return {
											label : item + ' ('+count+')',
											value : item
										};
									})
								)
							);
						},
						error : function () {}
					});
				},
				minLength: 1
			})
		})
	});

	$('#tag_editor,[name="bulk_tags"]').not('.tagit-hidden-field').each(function () {
		var $field = $(this);
		if ($field.data('tagit-initialized')) return;
		$field.data('tagit-initialized', true);
		var fieldPlaceholder = $field.attr('placeholder') || '';

		$field.tagit({
			singleFieldDelimiter: ' ',
			placeholderText: fieldPlaceholder,
			autocomplete : ({
				source: function (request, response) {
					$.ajax({
						url: base_href + '/api/internal/autocomplete',
						data: {'s': request.term},
						dataType : 'json',
						type : 'GET',
						success : function (data) {
							response(
								$.map(data, function (count, item) {
									return {
										label : item + ' ('+count+')',
										value : item
									};
								})
							);
						},
						error : function () {}
					});
				},
				minLength: 1
			})
		})
	});

	$('.ui-autocomplete-input').off('keydown.tagitfix').on('keydown.tagitfix', function(e) {
		var keyCode = e.keyCode || e.which;

		//Stop tags containing space.
		if(keyCode === 32) {
			e.preventDefault();

			$('.autocomplete_tags').tagit('createTag', $(this).val());
			$(this).autocomplete('close');
		} else if (keyCode === 9) {
			e.preventDefault();

			var tag = $('.tagit-autocomplete[style*=\"display: block\"] > li:focus, .tagit-autocomplete[style*=\"display: block\"] > li:first').first();
			if(tag.length){
				$(tag).click();
				$('.ui-autocomplete-input').val(''); //If tag already exists, make sure to remove duplicate.
			}
		}
	});
}

function bootTagAutocomplete(attempt) {
	if (window.jQuery && window.jQuery.fn && window.jQuery.fn.tagit) {
		initTagAutocomplete();
		return;
	}
	if ((attempt || 0) < 100) {
		setTimeout(function () { bootTagAutocomplete((attempt || 0) + 1); }, 50);
	}
}

document.addEventListener('DOMContentLoaded', () => {
	bootTagAutocomplete(0);
});

window.addEventListener('load', () => {
	bootTagAutocomplete(0);
});
