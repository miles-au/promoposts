module ApplicationHelper

  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = "Promo Posts - Social media for promo made easy."
    if page_title.empty?
      base_title
    else
      "Promo Posts | " + page_title
    end
  end

  def promodigi_title(page_title = '')
    base_title = "Custom Promotional Items"
    if page_title.empty?
      base_title
    else
      page_title + " | Custom Promotional Items"
    end
  end
  
end