jQuery ->
  $(window).on 'scroll', ->
      more_posts_url = $('.pagination .next_page a').attr('href')
      console.log(more_posts_url)
      if more_posts_url && $(window).scrollTop() > $(document).height() - $(window).height() - 60
        $('.pagination').html('Loading...')
        $.getScript more_posts_url
      return
      return
    