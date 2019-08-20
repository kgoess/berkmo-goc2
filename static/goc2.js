(function(){

function bindEventRowsToActions() {
    $(".event-table .an-event").bind('click', function(e) {
        e.preventDefault();
        var eventId = $(this).attr('data-event-id');
        var eventUrl = GoC.eventUrl.replace('{{id}}', eventId);
        document.location.href=eventUrl;
    });
}

/* function document.ready
 *
 * this gets called when the page loads, it's where we
 * attach all the things and get the ball rolling javascript-wise
 */
$(document).ready(function(){
    bindEventRowsToActions();

    $('.login-selectbox').on('change', function() {
        var val = $("#login-form-submit").prop("disabled", false);
    });

    // any place there's a "show inactive" checkbox
    $('.show-inactive').on('change', function () {
        $(this).parents("form").submit()
    });
});

})();

