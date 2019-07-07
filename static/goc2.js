(function(){

function bindEventRowsToActions() {
    $(".event-row").bind('click', function(e) {
        e.preventDefault();
        var eventId = $(this).attr('data-event-id');
        document.location.href="/goc2/event?id="+eventId;
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

});

})();

