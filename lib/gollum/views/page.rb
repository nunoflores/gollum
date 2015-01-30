require 'open-uri'
require 'json'
module Precious
  module Views
    class Page < Layout
      include HasPage

      attr_reader :content, :page, :header, :footer
      DATE_FORMAT    = "%Y-%m-%d %H:%M:%S"
      DEFAULT_AUTHOR = 'you'
      @@to_xml       = { :save_with => Nokogiri::XML::Node::SaveOptions::DEFAULT_XHTML ^ 1, :indent => 0, :encoding => 'UTF-8' }
      @@to_html = { :save_with => Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML, :indent => 2, :encoding => 'UTF-8', :indent_text => " " }

      def title
        h1 = @h1_title ? page_header_from_content(@content) : false
        h1 || @page.url_path_title
      end

      def page_header
        page_header_from_content(@content) || title
      end

      def content
        content_without_page_header(@content)
      end

      def author
        page_versions = @page.versions
        first         = page_versions ? page_versions.first : false
        return DEFAULT_AUTHOR unless first
        first.author.name.respond_to?(:force_encoding) ? first.author.name.force_encoding('UTF-8') : first.author.name
      end

      def date
        page_versions = @page.versions
        first         = page_versions ? page_versions.first : false
        return Time.now.strftime(DATE_FORMAT) unless first
        first.authored_date.strftime(DATE_FORMAT)
      end

      def noindex
        @version ? true : false
      end

      def editable
        @editable
      end

      def old_version
        @old_version
      end

      def page_exists
        @page_exists
      end

      def allow_uploads
        @allow_uploads
      end

      def upload_dest
        @upload_dest
      end

      def has_header
        @header = (@page.header || false) if @header.nil?
        !!@header
      end

      def header_content
        has_header && @header.formatted_data
      end

      def header_format
        has_header && @header.format.to_s
      end

      def has_footer
        @footer = (@page.footer || false) if @footer.nil?
        !!@footer
      end

      def footer_content
        has_footer && @footer.formatted_data
      end

      def footer_format
        has_footer && @footer.format.to_s
      end

      def bar_side
        @bar_side.to_s
      end

      def has_sidebar
        @sidebar = (@page.sidebar || false) if @sidebar.nil?
        !!@sidebar
      end

      def sidebar_content
        has_sidebar && @sidebar.formatted_data
      end

      def sidebar_format
        has_sidebar && @sidebar.format.to_s
      end

      def has_toc
        !@toc_content.nil?
      end

      def toc_content
        @toc_content
      end

      def mathjax
        @mathjax
      end

      def comments
        @comments
      end

      def show_comments
        build_comments
      end

      def show_sidebar_comments
        build_inline_comments
      end

      def has_comments
        @has_comments
      end

      def old_version
        @old_version
      end

      def old_comments
        if(@old_comments.nil?)
          Array.new
        else
          @old_comments
        end
      end

      def use_identicon
        @page.wiki.user_icons == 'identicon'
      end

      # Access to embedded metadata.
      #
      # Examples
      #
      #   {{#metadata}}{{name}}{{/metadata}}
      #
      # Returns Hash.
      def metadata
        @page.metadata
      end

      def page_url_path
        @page.url_path
      end

      private

      # Wraps page formatted data to Nokogiri::HTML document.
      #
      def build_document(content)
        Nokogiri::HTML::fragment(%{<div id="gollum-root">} + content.to_s + %{</div>}, 'UTF-8')
      end

      # Finds header node inside Nokogiri::HTML document.
      #
      def find_header_node(doc)
        case @page.format
        when :asciidoc
          doc.css("div#gollum-root > div#header > h1:first-child")
        when :org
          doc.css("div#gollum-root > p.title:first-child")
        when :pod
          doc.css("div#gollum-root > a.dummyTopAnchor:first-child + h1")
        when :rest
          doc.css("div#gollum-root > div > div > h1:first-child")
        else
          doc.css("div#gollum-root > h1:first-child")
        end
      end

      # Extracts title from page if present.
      #
      def page_header_from_content(content)
        doc   = build_document(content)
        title = find_header_node(doc).inner_text.strip
        title = nil if title.empty?
        title
      end

      # Returns page content without title if it was extracted.
      #
      def content_without_page_header(content)
        doc   = build_document(content)
        title = find_header_node(doc)
        title.remove unless title.empty?
        # .inner_html will cause href escaping on UTF-8
        doc.css("div#gollum-root").children.to_xml(@@to_xml)
      end

      def build_inline_comments_old
        @frag = Nokogiri::HTML::DocumentFragment.parse ""
        sorted_comments = @comments.sort {|a,b| DateTime.strptime(a[2],"%d/%m/%Y %H:%M") <=> DateTime.strptime(b[2],"%d/%m/%Y %H:%M")}
        sorted_comments.reverse!

        Nokogiri::HTML::Builder.with(@frag) do |doc|
          sorted_comments.each{|c|
            if(c['inline'] == 1)
              doc.div(:id => "comment-#{c['id']}", :class => "inline-comment", :section => "#{c['section']}", :style => ""){
                doc.a(:id => "show-button_#{c['id']}", :role => "button", :onclick => "show_inline_comments(#{c['id']});"){ doc.text "Show comments"}
                doc.br
                doc.div(:id => "content-#{c['id']}", :class => "inline-comment-content", :style => "display:none; word-wrap:break-word; width: 200px;", :section => "#{c['section']}"){ doc.text c['content'] }
              }
            end
          }
        end
        return @frag.to_html(@@to_html)
      end

      # SECOND METHOD, BUILD INLINE COMMENTS FOR EACH SECTION
      def build_inline_comments
        @frag = Nokogiri::HTML::DocumentFragment.parse ""
        sorted_comments = @comments.sort {|a,b| DateTime.strptime(a[2],"%d/%m/%Y %H:%M") <=> DateTime.strptime(b[2],"%d/%m/%Y %H:%M")}
        sorted_comments.reverse!

        # --------------------------
        # Display de avatars hardcoded temporariamente
        avatars = Hash.new
        avatars['nmlpsousa'] = "https://avatars.githubusercontent.com/u/1554191?v=3"
        avatars['nunoflores'] = "https://avatars.githubusercontent.com/u/598998?v=3"
        avatars['jmapsimoes'] = "https://avatars.githubusercontent.com/u/9195015?v=3"
        avatars['ribadmilo'] = "https://avatars.githubusercontent.com/u/1673931?v=3"
        # --------------------------

        Nokogiri::HTML::Builder.with(@frag) do |doc|
          @sections.each{|section|
            doc.div(:id => section, :class => "section-comment-area", :style => "background-color: \#ffffff;"){
              doc.a(:role => "button", :onclick => "show_section_comments(\"#{section}\");"){doc.text "Show"}
              doc.br
              doc.div(:id => "section-#{section}-comments", :class => "section-comments-content", :section => section, :style => "display: none;"){
                if(!@old_version)
                  doc.a(:role => "button", :onclick => "$(\'form#section-#{section}-form\').toggle(250);"){ doc.text "Add comment" }
                  doc.br
                  doc.form(:id => "section-#{section}-form", :class => "section-comment-form", :name => "insert-comment", :method => "POST", :action => "/insert_comment", :style => "display: none;"){
                    doc.textarea(:name => "comment_textarea", :cols => "40", :rows => "5")
                    doc.br
                    doc.input(:type => "hidden", :name => "page_url", :value => page_url_path)
                    doc.input(:type => "hidden", :name => "inline", :value => 1)
                    doc.input(:type => "hidden", :name => "section", :value => section)
                    doc.input(:type => "submit", :value => "Add comment")
                  }
                end
                sorted_comments.each{|c|
                  if(c['inline'] == 1 && c['section'] == section && c['parent'].nil? && (!@old_version || @old_comments.include?(c['id'])) )
                    id = c['id']
                    replies = Array.new
                    sorted_comments.each {|comment|
                      if(comment['parent'] == id && (!@old_version || @old_comments.include?(comment['id'])) )
                        replies.push comment
                      end
                    }
                    replies.sort! {|a,b| DateTime.strptime(a[2],"%d/%m/%Y %H:%M") <=> DateTime.strptime(b[2],"%d/%m/%Y %H:%M")}
                    replies.reverse!
                    doc.table(:border => 0, :cellpadding => 0, :width => "400px"){
                      doc.tr{
                        doc.td(:rowspan => "5", :class => "comment_avatar_cell"){
                          doc.div(:align => "center"){
                            if (avatars.has_key? c['author'])
                              avatar = avatars[c['author']]
                            else
                              avatar = "http://brandonmathis.com/projects/fancy-avatars/demo/images/avatar_male_dark_on_clear_200x200.png"
                            end
                            doc.div(:class => "comment_avatar", :style => "background: url("+avatar+"); background-size: 30px 30px; background-repeat: no-repeat;")
                            # doc.div(:class => "comment_avatar")
                          }
                        }
                        doc.td(:class => "cell_middle"){
                          doc.div(:class => "comment_username"){
                            doc.text c['author']
                          }
                          doc.div(:class => "trash_button"){
                            doc.a(:class => "delete-comment", :href => "#{base_url}/#{escaped_url_path}", :delete_comment => "Are you sure you want to delete this comment?", :comment_id => id){
                              doc.img(:src => "http://iconizer.net/files/Devine_icons/orig/Trash-Recyclebin-Empty-Closed.png", :width => "20px", :height => "20px")
                            }
                          }
                        }
                      }

                      doc.tr{
                        doc.td(:height => "100%"){
                          doc.div(:class => "comment_content"){
                            c['content'].each_line do |line|
                              doc.text line
                              doc.br
                            end
                          }
                          doc.div(:class => "date"){
                            # doc.text c['date']
                            date = DateTime.strptime(c['date'],"%d/%m/%Y %H:%M")
                            doc.text date.strftime("%b %-d, %Y %H:%M")
                          }
                        }
                      }

                      doc.tr{
                        doc.td(:style => "vertical-align: bottom;"){
                          doc.div(:class => "reply_toggle"){
                            doc.a(:class => "toggler", :id => "show-button_#{id}", :role => "button", :onclick => "$(\"#replies-#{id}\").toggle(250);"){
                              reply_count = replies.size
                              doc.text "Show replies (#{reply_count})"
                            }
                          }
                        }
                      }

                      doc.tr{
                        doc.td(:class => "replies_cell"){
                          doc.div(:id => "replies-#{id}", :style => "display: none;"){
                            replies.each do |reply|

                              # github_json_reply = JSON.load(open("https://api.github.com/users/"+reply['author']+"?access_token=3b936c639cd984592568c3b7fe6287410137c221"))
                              # avatar_url = github_json_reply['avatar_url']

                              doc.table(:border => "0", :cellpadding => "0", :cellspacing => "0"){
                                doc.tr{
                                  doc.td(:rowspan => "3", :class => "reply_avatar_cell"){
                                    doc.div(:align => "center"){
                                      if (avatars.has_key? reply['author'])
                                        avatar = avatars[reply['author']]
                                      else
                                        avatar = "http://brandonmathis.com/projects/fancy-avatars/demo/images/avatar_male_dark_on_clear_200x200.png"
                                      end
                                      doc.div(:class => "reply_avatar", :style => "background: url("+avatar+"); background-size: 30px 30px; background-repeat: no-repeat;")
                                      # doc.div(:class => "reply_avatar")
                                    }
                                  }
                                }
                                doc.tr{
                                  doc.td(:class => "cell_middle"){
                                    doc.div(:align => "center"){
                                      doc.div(:class => "reply_username"){
                                        doc.text reply['author']
                                      }
                                    }
                                  }
                                }
                                doc.tr{
                                  doc.td(:width => "100%"){
                                    doc.div(:class => "reply_content"){
                                      reply['content'].each_line do |line|
                                        doc.text line
                                        doc.br
                                      end
                                    }
                                    doc.div(:class => "date"){
                                      date = DateTime.strptime(c['date'],"%d/%m/%Y %H:%M")
                                      doc.text date.strftime("%b %-d, %Y %H:%M")
                                    }
                                  }
                                }
                              }
                            end
                          }
                        }
                      }


                      doc.tr{
                        doc.td(:width => "100%"){
                          if(c['deleted'] != 1 && !@old_version)
                            doc.form(:id => "reply-form-#{id}", :class => "comment-reply-form", :method => "POST", :name => "reply-comment", :action => "/insert_comment", :style => "display: none;"){
                              doc.textarea(:class => "comment_textarea", :name => "comment_textarea", :rows => "5")
                              doc.br
                              doc.input(:type => "hidden", :name => "parent_id", :value => id)
                              doc.input(:type => "hidden", :name => "page_url", :value => page_url_path)
                              doc.input(:type => "hidden", :name => "inline", :value => 1)
                              doc.input(:type => "hidden", :name => "section", :value => section)
                              doc.input(:type => "submit", :value => "Add reply")
                            }
                            doc.div(:class => "reply"){
                              doc.a(:role => "button", :onclick => "$(\"#reply-form-#{id}\").toggle(250);", :style => "color: \#00aa00;"){
                                doc.text "Reply to this comment"
                              }
                            }
                          end
                        }
                      }
                    }

                    # doc.div(:id => "#{c['id']}", :class => "inline-comment"){
                    #   doc.strong c['author']
                    #   doc.text " - "+c['date']
                    #   doc.br
                    #   c['content'].each_line do |line|
                    #     doc.text line
                    #     doc.br
                    #   end
                    #   if(c['deleted'] != 1 && !@old_version)
                    #     doc.form(:id => "reply-form-#{id}", :method => "POST", :name => "reply-comment", :action => "/insert_comment", :style => "display: none;") {
                    #       doc.textarea(:name => "comment_textarea", :cols => "40", :rows => "5")
                    #       doc.br
                    #       doc.input(:type => "hidden", :name => "parent_id", :value => id)
                    #       doc.input(:type => "hidden", :name => "inline", :value => 1)
                    #       doc.input(:type => "hidden", :name => "section", :value => section)
                    #       doc.input(:type => "hidden", :name => "page_url", :value => page_url_path)
                    #       doc.input(:type => "submit", :value => "Add reply")
                    #     }
                    #     doc.a(:role => "button", :onclick => "$(\"#reply-form-#{id}\").toggle(250);", :style => "font-size:80%;") {doc.text "Reply" }
                    #     if(c['author'] == @session_username || @is_admin)
                    #       doc.text " | "
                    #       doc.a(:class => "delete-comment", :href => "#{base_url}/#{escaped_url_path}", :delete_comment => "Are you sure you want to delete this comment?", :comment_id => id, :style => "font-size:80%;"){ doc.text "Delete" }
                    #     end
                    #   end
                    #   doc.div(:id => "replies-#{id}", :style => "margin-left:2em;"){
                    #     replies.each {|reply|
                    #       doc.strong "Author: "
                    #       doc.text reply['author']+' - '
                    #       doc.strong "Date: "
                    #       doc.text reply['date']
                    #       doc.br
                    #       reply['content'].each_line do |line|
                    #         doc.text line
                    #         doc.br
                    #       end
                    #     }
                    #   }
                    # }
                  end
                }
              }
            }
          }
        end
        return @frag.to_html(@@to_html)
      end

      def build_comments
        @docfrag = Nokogiri::HTML::DocumentFragment.parse ""
        # Here we sort the comments, newest comments first
        sorted_comments = @comments.sort {|a,b| DateTime.strptime(a[2],"%d/%m/%Y %H:%M") <=> DateTime.strptime(b[2],"%d/%m/%Y %H:%M")}
        sorted_comments.reverse!

        # --------------------------
        # Display de avatars hardcoded temporariamente
        avatars = Hash.new
        avatars['nmlpsousa'] = "https://avatars.githubusercontent.com/u/1554191?v=3"
        avatars['nunoflores'] = "https://avatars.githubusercontent.com/u/598998?v=3"
        avatars['jmapsimoes'] = "https://avatars.githubusercontent.com/u/9195015?v=3"
        avatars['ribadmilo'] = "https://avatars.githubusercontent.com/u/1673931?v=3"
        # --------------------------

        # We build the div section with the comments for this page
        Nokogiri::HTML::Builder.with(@docfrag) do |doc|
          doc.div(:id => "wiki-comments", :style => "clear: both; border-top: 1px solid #ddd; margin: 1em 0 7em;") {
            sorted_comments.each {|c|
              if(c['inline'] == 0 && (!@old_version || old_comments.include?(c['id'])))
                doc.div(:id => "comment-#{c['id']}", :class => "page-comment"){
                  if(c['parent'].nil?)
                    id = c['id']
                    replies = Array.new
                    sorted_comments.each {|comment|
                      if(comment['parent'] == id)
                        replies.push comment
                      end
                    }
                    replies.sort! {|a,b| DateTime.strptime(a[2],"%d/%m/%Y %H:%M") <=> DateTime.strptime(b[2],"%d/%m/%Y %H:%M")}
                    replies.reverse!

                    # --------------------------
                    # Display de avatars hardcoded temporariamente
                    avatars = Hash.new
                    avatars['nmlpsousa'] = "https://avatars.githubusercontent.com/u/1554191?v=3"
                    avatars['nunoflores'] = "https://avatars.githubusercontent.com/u/598998?v=3"
                    # --------------------------

                    # github_json = JSON.load(open("https://api.github.com/users/"+c['author']+"?access_token=3b936c639cd984592568c3b7fe6287410137c221"))
                    # avatar_url = github_json['avatar_url']

                    doc.table(:border => 0, :cellpadding => 0, :width => "400px"){
                      doc.tr{
                        doc.td(:rowspan => "5", :class => "comment_avatar_cell"){
                          doc.div(:align => "center"){
                            if (avatars.has_key? c['author'])
                              avatar = avatars[c['author']]
                            else
                              avatar = "http://brandonmathis.com/projects/fancy-avatars/demo/images/avatar_male_dark_on_clear_200x200.png"
                            end
                            doc.div(:class => "comment_avatar", :style => "background: url("+avatar+"); background-size: 30px 30px; background-repeat: no-repeat;")
                            # doc.div(:class => "comment_avatar")
                          }
                        }
                        doc.td(:class => "cell_middle"){
                          doc.div(:class => "comment_username"){
                            doc.text c['author']
                          }
                          doc.div(:class => "trash_button"){
                            doc.a(:class => "delete-comment", :href => "#{base_url}/#{escaped_url_path}", :delete_comment => "Are you sure you want to delete this comment?", :comment_id => id){
                              doc.img(:src => "http://iconizer.net/files/Devine_icons/orig/Trash-Recyclebin-Empty-Closed.png", :width => "20px", :height => "20px")
                            }
                          }
                        }
                      }

                      doc.tr{
                        doc.td(:height => "100%"){
                          doc.div(:class => "comment_content"){
                            c['content'].each_line do |line|
                              doc.text line
                              doc.br
                            end
                          }
                          doc.div(:class => "date"){
                            # doc.text c['date']
                            date = DateTime.strptime(c['date'],"%d/%m/%Y %H:%M")
                            doc.text date.strftime("%b %-d, %Y %H:%M")
                          }
                        }
                      }

                      doc.tr{
                        doc.td(:style => "vertical-align: bottom;"){
                          doc.div(:class => "reply_toggle"){
                            doc.a(:class => "toggler", :id => "show-button_#{id}", :role => "button", :onclick => "$(\"#replies-#{id}\").toggle(250);"){
                              reply_count = replies.size
                              doc.text "Show replies (#{reply_count})"
                            }
                          }
                        }
                      }

                      doc.tr{
                        doc.td(:class => "replies_cell"){
                          doc.div(:id => "replies-#{id}", :style => "display: none;"){
                            replies.each do |reply|

                              # github_json_reply = JSON.load(open("https://api.github.com/users/"+reply['author']+"?access_token=3b936c639cd984592568c3b7fe6287410137c221"))
                              # avatar_url = github_json_reply['avatar_url']

                              doc.table(:border => "0", :cellpadding => "0", :cellspacing => "0"){
                                doc.tr{
                                  doc.td(:rowspan => "3", :class => "reply_avatar_cell"){
                                    doc.div(:align => "center"){
                                      if (avatars.has_key? reply['author'])
                                        avatar = avatars[reply['author']]
                                      else
                                        avatar = "http://brandonmathis.com/projects/fancy-avatars/demo/images/avatar_male_dark_on_clear_200x200.png"
                                      end
                                      doc.div(:class => "reply_avatar", :style => "background: url("+avatar+"); background-size: 30px 30px; background-repeat: no-repeat;")
                                      # doc.div(:class => "reply_avatar")
                                    }
                                  }
                                }
                                doc.tr{
                                  doc.td(:class => "cell_middle"){
                                    doc.div(:align => "center"){
                                      doc.div(:class => "reply_username"){
                                        doc.text reply['author']
                                      }
                                    }
                                  }
                                }
                                doc.tr{
                                  doc.td(:width => "100%"){
                                    doc.div(:class => "reply_content"){
                                      reply['content'].each_line do |line|
                                        doc.text line
                                        doc.br
                                      end
                                    }
                                    doc.div(:class => "date"){
                                      date = DateTime.strptime(c['date'],"%d/%m/%Y %H:%M")
                                      doc.text date.strftime("%b %-d, %Y %H:%M")
                                    }
                                  }
                                }
                              }
                            end
                          }
                        }
                      }


                      doc.tr{
                        doc.td(:width => "100%"){
                          if(c['deleted'] != 1 && !@old_version)
                            doc.form(:id => "reply-form-#{id}", :class => "comment-reply-form", :method => "POST", :name => "reply-comment", :action => "/insert_comment", :style => "display: none;"){
                              doc.textarea(:class => "comment_textarea", :name => "comment_textarea", :rows => "5")
                              doc.br
                              doc.input(:type => "hidden", :name => "parent_id", :value => id)
                              doc.input(:type => "hidden", :name => "page_url", :value => page_url_path)
                              doc.input(:type => "submit", :value => "Add reply")
                            }
                            doc.div(:class => "reply"){
                              doc.a(:role => "button", :onclick => "$(\"#reply-form-#{id}\").toggle(250);", :style => "color: \#00aa00;"){
                                doc.text "Reply to this comment"
                              }
                            }
                          end
                        }
                      }
                    }

                    # doc.strong "Author: "
                    # doc.text c['author']+" - "
                    # doc.strong "Date: "
                    # doc.text c['date']+" "
                    # doc.a(:id => "show-button_#{id}", :role => "button", :onclick => "$(\"#replies-#{id}\").toggle(250);", :style => "font-size:80%;") {doc.text "Show/Hide replies"}
                    # doc.br
                    # c['content'].each_line do |line|
                    #   doc.text line
                    #   doc.br
                    # end

                    # if(c['deleted'] != 1 && !@old_version)
                    #   doc.div(:class => "comment-reply-div"){
                    #     doc.form(:id => "reply-form-#{id}", :class => "comment-reply-form", :method => "POST", :name => "reply-comment", :action => "/insert_comment", :style => "display: none;") {
                    #       doc.textarea(:name => "comment_textarea", :cols => "40", :rows => "5")
                    #       doc.br
                    #       doc.input(:type => "hidden", :name => "parent_id", :value => id)
                    #       doc.input(:type => "hidden", :name => "page_url", :value => page_url_path)
                    #       doc.input(:type => "submit", :value => "Add reply")
                    #     }
                    #   }
                    #   doc.a(:role => "button", :onclick => "$(\"#reply-form-#{id}\").toggle(250);", :style => "font-size:80%;") {doc.text "Reply" }
                    #   if(c['author'] == @session_username || @is_admin)
                    #     doc.text " | "
                    #     doc.a(:class => "delete-comment", :href => "#{base_url}/#{escaped_url_path}", :delete_comment => "Are you sure you want to delete this comment?", :comment_id => id, :style => "font-size:80%;"){ doc.text "Delete" }
                    #   end
                    # end
                    # doc.br
                    # doc.div(:id => "replies-#{id}", :style => "margin-left:2em;"){
                    #   replies.each {|reply|
                    #     doc.strong "Author: "
                    #     doc.text reply['author']+' - '
                    #     doc.strong "Date: "
                    #     doc.text reply['date']
                    #     doc.br
                    #     reply['content'].each_line do |line|
                    #       doc.text line
                    #       doc.br
                    #     end
                    #   }
                    # }
                  end
                }
              end
            }
          }
        end
        return @docfrag.to_html(@@to_html)
      end
    end
  end
end
