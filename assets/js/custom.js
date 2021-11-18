if (!window.cool) {
    var cool = {};
}

cool.slides = (function() {
    function goToSlide(x) {
      $('html, body').animate({
        scrollTop: $("#slideshow").offset().top
      }, 300, function() {
        $('.slide.active').fadeOut(300, function(e) {
          $('.active').removeClass('active');
          $('*[data-target-slide=' + x + ']').addClass('active');
          $('#slide-' + x).fadeIn(300).addClass('active');
        });
      });

    }

    return {
        goToSlide: goToSlide
    };

}());


cool.ohana = (function() {
  function bind() {
    const paths = ['diy', 'mix', 'managed'];

    $(paths.map(p => `.${p}`).join(', ')).fadeOut();

    $('.pathnav a.path').on('click', function(e) {
      $('body').addClass('active');
      $this = $(this);
      $('.pathnav .active').removeClass('active');
      $this.addClass('active');

      let path = $this.attr('data-path');

      $(paths.filter(p => p !== path).map(p => `.${p}`).join(', '))
        .not(`.${path}`)
        .fadeOut('fast', function() {
          $(`.${path}`).fadeIn();
        });

    });

    
  };
  $(".cicdchoice").change(function() {
    if (this.checked){
      $("#nocicd").css('display','none')
      $("#cicd").css('display','flex')
    }
    else{
      $("#nocicd").css('display','flex')
      $("#cicd").css('display','none')
    }
    
  });
  return {
    bind: bind
  };
}());

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

  $('#topic-filter').on('keyup', function(){
     var value = $(this).val().toLowerCase();
     $('.topics__list li').each(function () {
        if ($(this).text().toLowerCase().search(value) > -1) {
           $(this).show();
        } else {
           $(this).hide();
        }
     });
  });

  $('.author__bio').readmore({
    collapsedHeight: 200,
    moreLink: '<a href="#">More&hellip;</a>',
    lessLink: '<a href="#">Less&hellip;</a>',
    embedCSS: true });

  if ($('body').attr('id') === 'ohana') {
    cool.ohana.bind();
  }
});

