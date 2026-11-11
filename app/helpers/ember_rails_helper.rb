require "html_page/capture"

module EmberRailsHelper
  def render_ember_app(name, &block)
    EmberCli[name].build

    markup_capturer = HtmlPage::Capture.new(self, &block)

    head, body = markup_capturer.capture

    index_html = EmberCli[name].index_html(
      head: head,
      body: body,
      mount_point: ember_mount_point,
    )

    render html: index_html.html_safe
  end

  private

  # The mount point `mount_ember_app` declares for the route being served.
  #
  # It is written into the document's asset URLs, so read it from the route
  # alone: `params` also carries the query string and the request body, which
  # would let a request choose where a page rendered from any other route
  # loads its scripts from.
  def ember_mount_point
    request.path_parameters[:ember_mount_point]
  end
end
