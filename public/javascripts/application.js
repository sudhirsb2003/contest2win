function selectAll(classname, checked) { $$('.'+classname).each(function(e){e.checked=checked;e.onclick();}); }
function toggleAll(classname) { $$('.'+classname).each(function(e){e.checked=!e.checked;e.onclick();}); }
String.prototype.trim = function() { return this.replace(/^\s+|\s+$/, ''); };
function showTab(tab, parent, callback) {
  if ($(tab+'_body').hasClassName('to_fetch')) {
    if (!callback) callback = loadTab;
    $(tab+'_body').innerHTML = '<div class="loading_small"></div>';
    callback(tab);
    $(tab+'_body').removeClassName('to_fetch');
  }
  $$(parent + " ul.tabs li").each(function(e) {e.removeClassName('selected')})
  $$(parent + " div.tab_body > div").each(function(e) {e.hide()})
  $(tab + '_tab').addClassName("selected");
  $(tab + '_body').show();
}
function show_media_tab(tab_name) {
	$$('.media_tab_body').each(Element.hide);
	$(tab_name+'_form').show();

	$$('#question_form_media .current').each(function(e) {e.removeClassName('current')});
	$(tab_name+'_tab').addClassName('current');
	$('question_content_type').value = tab_name == 'qf_img' ? 'Image' : tab_name == 'qf_vid' ? 'Video' : tab_name == 'qf_url' ? 'YTVideo' : 'Text';

	return false;
}
String.prototype.trim = function() { return this.replace(/^\s+|\s+$/g, ''); };

function calc_payout(wager, pool, total_wager) {
  payout = wager * (1 + (pool/(wager + total_wager)));
  if(isNaN(payout)) {
    return 'Invalid amount!';
  } else {
    return Math.round(payout*Math.pow(10,2))/Math.pow(10,2);
  }
}
String.prototype.pad = function(l, s, t){
return s || (s = " "), (l -= this.length) > 0 ? (s = new Array(Math.ceil(l / s.length) + 1).join(s)).substr(0, t = !t ? l : t == 1 ? 0 : Math.ceil(l / 2)) + this + s.substr(0, l - t) : this;
};

function postToFB(args) {
  FB.ui(eval('(' + args + ')'), function(response) {
    if (response && response.post_id) {
      //alert('Post was published.');
    } else {
      //alert('Post was not published.');
    }
  });
}

