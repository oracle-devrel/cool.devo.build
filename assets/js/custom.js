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
