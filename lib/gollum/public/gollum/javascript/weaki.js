function reloadSubmitEvents(){
  $('.comment-reply-div').on('submit',function(event){
    var object = $(this);
    var post_url = $(this).children('form').attr('action');
    var text = $(this).find('textarea[name="comment_textarea"]').val();
    var page_url = $(this).find('input[name="page_url"]').val();
    var parent_id = $(this).find('input[name="parent_id"]').val();
    if(text == ""){
      return false;
    }
    $.ajax({
      type: "POST",
      url: post_url,
      data:{
        comment_textarea: text,
        page_url: page_url,
        parent_id: parent_id
      },
      success: function(data){
        $.get(document.URL+" #wiki-comments", function(data){
          $('div#wiki-comments').replaceWith($(data).find('#wiki-comments'));
        });
        object.find('textarea[name="comment_textarea"]').val("");
        reloadSubmitEvents();
      }
    });

    //return false;
    event.preventDefault();
  });

  $('.section-comment-form').on('submit',function(){
    var form_data = $(this).serialize();
    var post_url = $(this).attr('action');
    var div = $(this).closest('div').attr('id');
    // var text = $(this).find('textarea[name="comment_textarea"]').val();
    // var page_url = $(this).find('input[name="page_url"]').val();
    // var parent_id = $(this).find('input[name="parent_id"]').val();
    // console.log(parent_id);
    // var inline = $(this).find('input[name="inline"]').val();
    // var section = $(this).find('input[name="section"]').val();
    $.ajax({
      type: "POST",
      url: post_url,
      data: form_data,
      success: function(data){
        $.get(document.URL+' #'+div, function(data){
          $('div#'+div).replaceWith($(data).find('#'+div));
        });
        reloadSubmitEvents();
      }
    });

    return false;
  });
}

$(document).ready(function(){
  // $(".inline-comment").each(function(){
  //   var section = $(this).attr("section");
  //   var object = "span#"+section;
  //   var pos_top = $(object).position().top;
  //   var pos_left = $("#comments-sidebar").offset().left;
  //   //$(this).offset({top:pos_top, left: pos_left});
  //   $(this).css("position","absolute");
  //   $(this).css("top",pos_top);
  //   $(this).css("left",pos_left);
  // });

    $('.comment-reply-div').on('submit',function(event){
      var object = $(this);
      var post_url = $(this).children('form').attr('action');
      var text = $(this).find('textarea[name="comment_textarea"]').val();
      var page_url = $(this).find('input[name="page_url"]').val();
      var parent_id = $(this).find('input[name="parent_id"]').val();
      if(text == ""){
        return false;
      }
      $.ajax({
        type: "POST",
        url: post_url,
        data:{
          comment_textarea: text,
          page_url: page_url,
          parent_id: parent_id
        },
        success: function(data){
          $.get(document.URL+" #wiki-comments", function(data){
            $('div#wiki-comments').replaceWith($(data).find('#wiki-comments'));
            reloadSubmitEvents();
          });
          object.find('textarea[name="comment_textarea"]').val("");
        }
      });

      //return false;
      event.preventDefault();
    });

  
  $('div#insert-comment').on('submit',function(){
    var post_url = $(this).children('form').attr('action');
    var text = $(this).find('textarea[name="comment_textarea"]').val();
    var page_url = $(this).find('input[name="page_url"]').val();
    if(text == ""){
      return false;
    }
    $.ajax({
      type: "POST",
      url: post_url,
      data:{
        comment_textarea: text,
        page_url: page_url
      },
      success: function(data){
        $.get(document.URL+" #wiki-comments", function(data){
          $('div#wiki-comments').replaceWith($(data).find('#wiki-comments'));
        });
        $('#insert-comment').find('textarea[name="comment_textarea"]').val("");
      }
    });

    return false;
  });

  $('.section-comment-area').each(function(){
    var section = $(this).attr('id');
    var object = 'span#'+section;
    var pos_top = $(object).position().top;
    var pos_left = $('#comments-sidebar').offset().left;
    $(this).css('position','absolute');
    $(this).css('top',pos_top);
    $(this).css('left',pos_left);
  });

  // var top_sidebar = $('#comments-sidebar').offset().top;
  // var left_sidebar = $('div#head').offset().left + $('div#head').width();
  // $('div#sidebar-comments-content').css('position','absolute');
  // $('div#sidebar-comments-content').css('top',top_sidebar);
  // $('div#sidebar-comments-content').css('left',left_sidebar);
  // $('div#sidebar-comments-content').text('Teste');
});

// $('.inline-comment-content').each(function(){
//   var left = $('div#comments-sidebar').offset().left;
//   var end = left + $('div#comments-sidebar').width();
//   $(this).css("position","absolute");
//   $(this).css("left",end);
// });

function show_inline_comments(id){
  $(".inline-comment-content").each(function(){
    var cid = 'content-'+id;
    if($(this).attr('id') != cid){
      $(this).hide();
    }
    else {
      // var parent = $(this).parent();
      // var parent_top = parent.css('top');
      // var parent_left = parent.css('left') + parent.width() + 50;
      var top = $(this).parent().height() * -1;
      $(this).toggle(250);
      $(this).css('position','relative');
      $(this).css('top',top)
      $(this).css('left','150px');
      // $(this).offset({top:pos_top,left:pos_left});
    }
  });
}

function show_section_comments(section){
  $(".section-comments-content").each(function(){
    var section_id = "section-"+section+"-comments";
    if($(this).attr('id') != section_id){
      $(this).hide();
    }
    else {
      var top = $(this).parent().height() * -1;
      $(this).toggle();
      $(this).css('position','relative');
      $(this).css('top',top);
      $(this).css('left','100px');
    }
  });
}