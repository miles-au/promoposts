// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//= require jquery
//= require bindWithDelay
//= require popper
//= require bootstrap
//= require jsTimezoneDetect
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require_tree .

$(document).ready(function () {
	if (window.location.href.indexOf('#_=_') > 0) {
		window.history.replaceState('', document.title, window.location.pathname);
	}
});

function show_tooltips(){
	$('[data-toggle="tooltip"]').tooltip({html: true});
}

function escapeHtml(unsafe) {
    return unsafe
         .replace(/&/g, "&amp;")
         .replace(/</g, "&lt;")
         .replace(/>/g, "&gt;")
         .replace(/"/g, "&quot;")
         .replace(/'/g, "&#039;");
}

var profileWidth = $("#profile_pic").width();
$("#profile_pic").height(profileWidth);

