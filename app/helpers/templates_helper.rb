module TemplatesHelper

  def site_templates
    @site_templates ||= current_site.templates.alpha
  end

  def current_template
    @current_template ||= begin
      if current_page.nil?
        p = params[:template_slug] || params[:slug]
        current_site.templates.find_by_slug(p)
      else
        current_page.template
      end
    end
  end

  def current_template_pages
    @current_template_pages ||= current_template.webpages.alpha
  end

  def current_template_pages_paginated
    @current_template_pages_paginated ||= begin
      Kaminari.paginate_array(current_template_pages).page(params[:page]).per(10)
    end
  end

  def current_template_groups
    @current_template_groups ||= begin
      current_template.groups.in_order.includes(:template_fields)
    end
  end

  def current_template_group
    @current_template_group ||= begin
      current_template_groups.select { |g| g.slug == params[:slug] }.first
    end
  end

  def current_template_fields
    @current_template_fields ||= begin
      current_template.fields
    end
  end

  def current_template_field
    @current_template_field ||= begin
      current_template_fields.select { |f| f.slug == params[:slug] }.first
    end
  end

  def current_template_group_fields
    @current_template_group_fields ||= current_template_group.fields
  end

  def site_has_templates?
    site_templates.size > 0
  end

  def template_children
    @template_children ||= begin
      children = current_template.children.reject(&:blank?)
      site_templates.select { |t| children.include?(t.slug) }
    end
  end

  def template_field_options
    [
      ['String', 'string'],
      ['Text', 'text'],
      ['Dropdown', 'select'],
      ['Date', 'date'],
      ['Checkbox', 'boolean'],
      ['Checkboxes', 'check_boxes'],
      ['Radio Buttons', 'radio_buttons'],
      # ['Date & Time', 'datetime'],
      ['File', 'file']
      # ['Image', 'image'],
    ]
  end

  def order_by_fields
    fields = []
    current_template.fields.each { |f| fields << [f.title, f.slug] }
    ([
      ['Title','title'],
      ['URL','slug'],
      ['Position','position'],
      ['Created','created_at'],
      ['Updated','updated_at'],
    ] + fields).uniq.sort
  end

  def current_template_actions
    s = current_site
    t = current_template
    [
      {
        :title => 'Pages', 
        :path => builder_route([t, current_template_pages], :index), 
        :class => 'pages'
      },
      {
        :title => 'Form Fields', 
        :path => builder_route([t, t.fields], :index), 
        :controllers => ['fields', 'groups'],
        :class => 'form'
      },
      {
        :title => 'Edit Template', 
        :path => edit_builder_site_template_path(s, t),
        :class => 'edit'
      },
      {
        :title => 'Developer Help', 
        :path => builder_route([t], :show), 
        :class => 'help'
      }
    ]
  end

  def current_template_breadcrumbs
    content_tag(:nav, :class => 'breadcrumbs') do
      content_tag(:ul) do
        o = content_tag(
          :li, 
          link_to('All Templates', builder_route([site_templates], :index))
        )
        if current_template.id
          o += content_tag(
            :li, 
            link_to(
              current_template.title, 
              builder_route([current_template], :show)
            )
          )
          if ['fields','groups'].include?(controller_name)
            o += content_tag(
              :li, 
              link_to(
                'Form Fields', 
                builder_route(
                  [current_template, current_template_fields], 
                  :index
                )
              )
            )
            o += content_tag(
              :li, 
              link_to(
                "#{action_name.titleize} #{controller_name.singularize.titleize}", 
                request.path
              )
            ) unless action_name == 'index'
          else
            o += content_tag(
              :li, 
              link_to(request.path.split('/').last.titleize, request.path)
            ) unless action_name == 'index'
          end
          o.html_safe
        end
      end
    end
  end

  def quick_template_status(template)
    if !template.limit_pages?
      link_to('', '#', :class => 'disabled unlimited')
    elsif template.maxed_out?
      link_to('', '#', :class => 'disabled maxed-out')
    else
      link_to('', '#', :class => 'disabled not-maxed')
    end
  end

  def template_status_filters
    o = link_to(
      "All",
      builder_site_templates_path(current_site, :tmpl_status => 'all'),
      :class => params[:tmpl_status] == 'all' ? 'active' : nil
    )
    o += link_to(
      "Unlimited",
      builder_site_templates_path(current_site, :tmpl_status => 'unlimited'),
      :class => "unlimited 
        #{params[:tmpl_status] == 'unlimited' ? 'active' : nil}"
    )
    o += link_to(
      "Not Maxed",
      builder_site_templates_path(current_site, :tmpl_status => 'not_maxed'),
      :class => "not-maxed 
        #{params[:tmpl_status] == 'not_maxed' ? 'active' : nil}"
    )
    o += link_to(
      "Maxed Out",
      builder_site_templates_path(current_site, :tmpl_status => 'maxed_out'),
      :class => "maxed-out 
        #{params[:tmpl_status] == 'maxed_out' ? 'active' : nil}"
    )
    o.html_safe
  end

  def template_last_edited(template)
    date = template.updated_at.strftime("%h %d")
    if template.last_editor
      editor = " by #{content_tag(:span, template.last_editor.display_name)}"
    else
      editor = ''
    end
    content_tag(:span, :class => 'last-edited') do
      "Last edited #{content_tag(:span, date)}#{editor}".html_safe
    end
  end

end
