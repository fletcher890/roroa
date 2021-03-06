module Roroacms  
  module CommentsHelper

    # returns the html for the error display for the comments form
    # Params:
    # +content+:: is the Comment ActiveRecord object with the errors

    def comments_error_display(content = nil)

      html = ''

      if content.errors.any?
        html = "<div id='error-explanation'>
  			<h2>Invalid:</h2><ul>"
        content.errors.full_messages.each do |msg|
          html += "<li>#{msg}</li>"
        end
        html += "</ul>
  			</div>"
      end

      html
    end


    # returns a success message if the comment has been saved successfully

    def comments_success_message
      html = '<div class="success">' + I18n.t("helpers.comments_helper.comments_success_message") + '</div>'.html_safe
    end


    # returns true or false as to wether the admin has comments turned on

    def comments_on
      Setting.get('article_comments') == 'Y' && Setting.get('article_comment_type') == 'R'
    end

  end
end