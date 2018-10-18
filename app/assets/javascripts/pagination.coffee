$(window).bindWithDelay 'scroll', ->
  jQuery ->
  $(window).on 'scroll', ->
      more_posts_url = $('.pagination .next_page a').attr('href')
      console.log(more_posts_url)
      if more_posts_url && $(window).scrollTop() > $(document).height() - $(window).height() - 60
        $('.pagination').html('<img src="/assets/loading.gif" alt="Loading..." title="Loading..." width="50px" style="display: inline-block;"/><h3 style="display: inline-block; margin-left: 20px;">Loading</h3>')
        $.getScript more_posts_url
      return
      return
, 100