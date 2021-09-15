$(document).ready(function() {
  $('.classifications__nav a').on('click', function(e) {
    $('.classifications section.active, .tagposts__tag.active').removeClass('active');
    var tag = $(this).attr('href');

    $(tag).addClass('active');
  });

  $('.topics__tag a').on('click', function(e) {
    $('.tagposts__tag.active').removeClass('active');
    var tag = $(this).attr('href');
    $(tag).addClass('active');
  });
});

if (!window.cool) {
    var cool = {};
}

cool.slides = (function() {
    function goToSlide(x) {
      $('.slide.active').fadeOut(300, function(e) {
        $('.active').removeClass('active');
        $('*[data-target-slide=' + x + ']').addClass('active');
        $('#slide-' + x).fadeIn(300).addClass('active');
        window.scrollTo(0, 0);
      });
    }

    return {
        goToSlide: goToSlide
    };

}());
