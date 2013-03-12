
//HTML 5 BLOCK ELEMENTS
    document.createElement("article");
	document.createElement("aside");  
    document.createElement("footer");  
    document.createElement("header");
	document.createElement("section");  
    document.createElement("hgroup");  
    document.createElement("nav");
	document.createElement("image-contaner"); 
	document.createElement("quiz-block");
	 document.createElement("add-quiz-block");
	
	// TextBox effect
jQuery(document).ready(function(){
	jQuery('input').each(function(){
		var txtval = jQuery(this).val();
		jQuery(this).focus(function(){
			jQuery(this).val('')
		});
		jQuery(this).blur(function(){
			if(jQuery(this).val() == ""){
				jQuery(this).val(txtval);
			}
		});
	});
});

// JavaScript Document


//VIEW MORE TEXT
function showHide(shID) {
   if (document.getElementById(shID)) {
      if (document.getElementById(shID+'-show').style.display != 'none') {
         document.getElementById(shID+'-show').style.display = 'none';
         document.getElementById(shID).style.display = 'block';
      }
      else {
         document.getElementById(shID+'-show').style.display = 'inline';
         document.getElementById(shID).style.display = 'none';
      }
   }
}
