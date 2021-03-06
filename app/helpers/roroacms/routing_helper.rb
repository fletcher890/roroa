module Roroacms 
  module RoutingHelper

    # renders the homepage that is set in the admin panel - unless it has search parameters,
    # it will render the search results page if it does have search parameters.
    # Params:
    # +params+:: all the current parameters. This is mainly used for the search results

    def route_index_page(params)

      if defined?(params[:search]) && !params[:search].blank?

        # make the content avalible to the view
        gloalize Post.where("(post_title LIKE :p or post_slug LIKE :p2 or post_content LIKE :p3) AND (post_type != 'autosave') AND (post_date <= CURRENT_TIMESTAMP)", { p: "%#{params[:search]}%", p2: "%#{params[:search]}%", p3: "%#{params[:search]}%" }).page(params[:page]).per(Setting.get('pagination_per_fe'))

        # add breadcrumbs to the hash
        add_breadcrumb I18n.t("generic.home"), :root_path, :title => I18n.t("generic.home")
        add_breadcrumb I18n.t("generic.search"), "/"

        # template Hierarchy
        do_hierarchy_templating('search')

      else

        @content = Post.find_by_id(Setting.get('home_page'))
        render_404 and return if @content.blank? || @content.post_status != 'Published'
        # make the content avalible to the view
        gloalize @content
        render_template 'home'

      end

    end


    # is used to find out if the requested is an article or a page
    # if it is a post it will prepend the url with the article url
    # Params:
    # +params+:: all the current parameters

    def show_url(params)

      post = Post.find(params[:id])
      article_url = Setting.get('articles_slug')
      url = '' 

      # if the post is an article. Prepend the url with the article url
      if post.post_type == 'post'
        url = "/#{article_url}/#{post.post_slug}?admin_preview=true"
      else
        url += "#{post.structured_url}?admin_preview=true"
      end

      url

    end



    # this is the function that gets the url and decides what to display
    # with the given content. This is the main function for routing. Nearly every request runs through this function
    # Params:
    # +params+:: all the current parameters


    def route_dynamic_page(params)

      # split the url up into segments
      segments = params[:slug].split('/')

      # general variables
      url = params[:slug]
      article_url = Setting.get('articles_slug')
      category_url = Setting.get('category_slug')
      tag_url = Setting.get('tag_slug')

      status = "(post_status = 'Published' AND post_date <= CURRENT_TIMESTAMP AND disabled = 'N')"
      # is it a article post or a page post
      case get_type_by_url
      when "CT"
        render_category segments, article_url, true, status
      when "AR"
        render_archive segments, article_url
      when "A"
        render_single segments, article_url, status
      when "C"
        render_category segments, article_url, false, status
      when "P"
        render_page url, status
      end

    end

    # returns that type of page that you are currenly viewing

    def get_type_by_url

      return 'P' if params[:slug].blank?

      # split the url up into segments
      segments = params[:slug].split('/')

      # general variables
      url = params[:slug]
      article_url = Setting.get('articles_slug')
      category_url = Setting.get('category_slug')
      tag_url = Setting.get('tag_slug')

      status = "(post_status = 'Published' AND post_date <= CURRENT_TIMESTAMP AND disabled = 'N')"

      # HACK: this needs to be optimised
      
      # is it a article post or a page post
      if segments[0] == article_url
        if !segments[1].blank?
          if segments[1] == category_url || segments[1] == tag_url
            # render a category or tag page
            return 'CT'
          elsif segments[1].match(/\A\+?\d+(?:\.\d+)?\Z/)
            # render the archive page
            return 'AR'
          else
            # otherwise render a single article page
            return 'A'
          end
        else
          # render the overall all the articles
          return 'C'
        end

      else
        # render a page
        return 'P'
      end

    end

    # renders a standard post page
    # Params:
    # +url+:: the url that has been requested by the user
    # +status+:: is passed in from the above function - just sets the standard status this is needed for the admin


    def render_page(url, status)
      # get content - if the admin isn't logged in your add the extra status requirements
      if !current_user.blank? && !params[:admin_preview].blank? && params[:admin_preview] == 'true'
        @content = Post.where("post_type = 'page' AND post_visible = 'Y' AND (post_status = 'Published' OR post_status = 'Draft')").find_by_structured_url("/#{url}")
      else
        @content = Post.where(status + " AND post_type = 'page' AND post_visible = 'Y'").find_by_structured_url("/#{url}")
      end

      # add a breadcrumb for each of its parents by running through each segment
      url.split('/').each do |u|
        p = Post.where(:post_type => 'page').find_by_post_slug(u)
        if p
          add_breadcrumb "#{p.post_title.capitalize}", "#{p.structured_url}", :title => "Back to #{p.post_title.capitalize}"
        end
      end
      # if content if blank return a 404
      render_404 and return if @content.blank?
      gloalize @content

      # if the content id is the same as the home page redirect to the home page do not render the content
      if !Setting.get('home_page').blank? && Setting.get('home_page').to_i == @content.id
        redirect_to site_url
      else
        render_template 'page'
      end

    end


    # renders a category, tag or view all articles page
    # Params:
    # +segments+:: an array of the url segments split via "/"
    # +article_url+:: is the url extension to show all articles
    # +term+:: wether you want to display more than just the home article display i.e. /articles/category/gardening
    # +status+:: the general status of the posts

    def render_category(segments, article_url = nil, term = false, status)
      category_url = Setting.get('category_slug')
      tag_slug = Setting.get('tag_slug')

      # do you want to filter the results down further than the top level
      if term

        if segments[2].blank?
          # if segment 2 is blank then you want to disply the top level article page
          redirect_to site_url(article_url)
        else
          term_type = 
            if segments[1] == category_url
              'category'
            elsif segments[1] == tag_slug
              'tag'
            else
              nil
            end
          segments.shift(2)
          term = Term.where(:structured_url => '/' + segments.join('/')).first

          # do a search for the content
          gloalize Post.joins(terms: :term_anatomy).where("post_status = 'Published' AND post_type != 'autosave' AND post_date <= CURRENT_TIMESTAMP AND disabled = 'N' AND roroacms_terms.id = ? ", term).where(roroacms_term_anatomies: {taxonomy: term_type}).order('post_date DESC').page(params[:page]).per(Setting.get('pagination_per_fe'))

          # add the breadcrumbs
          add_breadcrumb "#{article_url.capitalize}", "/#{article_url}", :title => I18n.t("helpers.routing_helper.generic.back_to", word: article_url.capitalize)
          segments.each do |f|
            term = Term.find_by_slug(f)
            if term.blank?
              render_404 and return
            end
            type_url = term.term_anatomy.taxonomy == 'tag' ? tag_slug : category_url
            add_breadcrumb "#{term.name.capitalize}", "/#{article_url}/#{type_url}#{term.structured_url}", :title => I18n.t("helpers.routing_helper.generic.back_to", word: term.name.capitalize)
          end

          do_hierarchy_templating('category')

        end

      else

        # add article homepage
        add_breadcrumb "#{article_url.capitalize}", "/#{article_url}", :title => I18n.t("helpers.routing_helper.generic.back_to", word: article_url.capitalize)
        gloalize Post.where("#{status} and post_type ='post' and disabled = 'N'").order('post_date DESC').page(params[:page]).per(Setting.get('pagination_per_fe'))

        # template Hierarchy
        do_hierarchy_templating('category')

      end

    end


    # renders a single article page
    # Params:
    # +segments+:: an array of the url segments split via "/"
    # +article_url+:: is the url extension to show all articles
    # +status+:: the general status of the posts

    def render_single(segments, article_url, status)
      # get content - if the admin isn't logged in your add the extra status requirements
      if !current_user.blank? && !params[:admin_preview].blank? && params[:admin_preview] == 'true'
        @content = Post.where("post_type = 'post' AND post_visible = 'Y' AND (post_status = 'Published' OR post_status = 'Draft')").find_by_post_slug(segments[1])
      else
        @content = Post.where(status + " AND post_type = 'post' AND post_visible = 'Y'").find_by_post_slug(segments[1])
      end

      render_404 and return if @content.nil?
      gloalize @content

      # create a new comment object for the comment form
      @new_comment = Comment.new

      # add the necessary breadcrumbs
      add_breadcrumb "#{article_url.capitalize}", "/#{article_url}", :title => I18n.t("helpers.routing_helper.generic.back_to", word: article_url.capitalize)
      add_breadcrumb "#{@content.post_title}", "/#{@content.post_title}", :title => I18n.t("helpers.routing_helper.generic.back_to", word: @content.post_title)

      # render the single template
      render_template 'article'

    end


    # renders a archive of articles - this could do with some refactoring
    # Params:
    # +segments+:: an array of the url segments split via "/"
    # +article_url+:: is the url extension to show all articles

    def render_archive(segments, article_url)

      # add the breadcrumb
      add_breadcrumb "#{article_url.capitalize}", "/#{article_url}", :title => I18n.t("helpers.routing_helper.generic.back_to", word: article_url.capitalize)

      # add for year as minimum
      add_breadcrumb "#{segments[1]}", "/#{article_url}/#{segments[1]}", :title => I18n.t("helpers.routing_helper.generic.back_to", word: segments[1])

      # build SQL variable
      build_sql = Post.where("(disabled = 'N' AND post_status = 'Published') AND post_type = 'post' AND (EXTRACT(year from post_date) = ?)", segments[1])


      if !segments[2].blank?
        #  add to SQL query
        build_sql = build_sql.where("EXTRACT(month from post_date) = ?", segments[2])
        # add the breadcrumbs
        add_breadcrumb "#{get_date_name_by_number(segments[2].to_i)}", "/#{article_url}/#{segments[1]}/#{segments[2]}", :title => I18n.t("helpers.routing_helper.generic.back_to", word: segments[2])
      end

      if !segments[3].blank?
        #  add to SQL query
        build_sql = build_sql.where("EXTRACT(day from post_date) = ?", segments[3])
        # add the breadcrumbs
        add_breadcrumb "#{segments[3]}", "/#{article_url}/#{segments[1]}/#{segments[2]}/#{segments[3]}", :title => I18n.t("helpers.routing_helper.generic.back_to", word: segments[3])
      end


      #  add to SQL query
      build_sql = build_sql.where("post_date <= NOW()")

      #  do seach for the content within the given parameters
      gloalize build_sql.order('post_date DESC').page(params[:page]).per(Setting.get('pagination_per_fe'))

      do_hierarchy_templating('archive')

    end

    # returns a boolean as to wether the template file actually exist in the theme?

    def template_exists?(path)
      File.exists?("#{Rails.root}/app/views/themes/#{current_theme}/" + path + '.' + get_theme_ext)
    end

    # checks for the top level file, but returns the file that it can actually use
    # Params:
    # +type+:: type of

    def do_hierarchy_templating(type)

      case type
      when 'archive'

        if template_exists?("archive")
          render :template => "themes/#{current_theme}/archive." + get_theme_ext
        elsif template_exists?("category")
          render :template => "themes/#{current_theme}/category." + get_theme_ext
        else
          render :template => "themes/#{current_theme}/page." + get_theme_ext
        end

      when 'category'

        if template_exists?("category")
          render :template => "themes/#{current_theme}/category." + get_theme_ext
        else
          render :template => "themes/#{current_theme}/page." + get_theme_ext
        end

      when 'search'

        if template_exists?("category")
          render :template => "themes/#{current_theme}/search." + get_theme_ext
        else
          render :tempalte => "themes/#{current_theme}/page." + get_theme_ext
        end

      end

    end

    # changes the view to use the given template if it doesn't exist it will just use the page.html.erb
    # the template file is set in the admin panel on each individual page.
    # Params:
    # +name+:: the template file to use.

    def render_template(name)
      if !@content.post_template.blank?

        # check if the template file actually exists
        if template_exists?("template-#{@content.post_template.downcase}")

          render :template => "themes/#{current_theme}/template-#{@content.post_template.downcase}." + get_theme_ext

        else

          # check if a file with the given name exists
          if template_exists?(name)
            render :template => "themes/#{current_theme}/#{name}." + get_theme_ext
          elsif template_exists?("page")
            # if not use the page.html.erb template which has to be included in the theme
            render :template => "themes/#{current_theme}/page." + get_theme_ext
          else
            render :inline => I18n.t("helpers.routing_helper.render_template.template_error")
          end

        end

      else

        # check if a file with the given name exists
        if template_exists?(name)
          render :template => "themes/#{current_theme}/#{name}." + get_theme_ext
        elsif template_exists?("page")
          # if not use the page.html.erb template which has to be included in the theme
          render :template => "themes/#{current_theme}/page." + get_theme_ext
        else
          render :inline => I18n.t("helpers.routing_helper.render_template.template_error")
        end

      end

    end

  end
end