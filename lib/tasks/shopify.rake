namespace :shopify do
  task :pdfGenerator => :environment do
    begin
      # ========================================= #
      ShopifyAPI::Base.site = SHOP_URL
      count = ShopifyAPI::Product.count
      page = 1
      products = []
      while count > 0 do
        products << ShopifyAPI::Product.find(:all, :params => {:page => page})
        count = count - 50
        page = page + 1
      end
      products.flatten!
      # ========================================= #

      if products.present?
        directory_name = "#{SHOPNAME}_pdf"
        Dir.mkdir(directory_name) unless File.exists?(directory_name)

        products.each do |product|
          _product = Product.create(product_id: product.id, title: product.title, body_html: product.body_html, dump: product)
          unless (product.metafields.present? && product.metafields.first.value.present?) && (product.metafields.first.updated_at > product.updated_at)

            # ==================================================================== #
            # ==================================================================== #

            begin
              Prawn::Document.generate(File.join(Dir.pwd, "#{directory_name}/#{product.title}-#{product.id}.pdf"), :margin => [30, 0, 0, 0]) do
                font_families.update("Helvetica" => {
                                         normal: "/home/ashish/Downloads/Open_Sans/normal.ttf",
                                         bold: "/home/ashish/Downloads/Open_Sans/bold.ttf",
                                         bold_italic: "/home/ashish/Downloads/Open_Sans/bold_italic.ttf",
                                         italic: "/home/ashish/Downloads/Open_Sans/normal.ttf",
                                         others: "/home/ashish/Downloads/Open_Sans/Garamond.ttf"
                                     })
                # ======================= Different details ======================= #
                _content_table_array = []
                _content_table_array << [{content: " "}]
                _product.grab_heading_and_content.each do |x|
                  _content_table_array << [{content: "<font size=16><color rgb='b20838'><u>#{x[0].remove_non_ascii.strip.upcase}</u></color></font>", inline_format: true, align: :left, padding: [0, 0, 0, 30], font_style: :italic}]
                  _content_table_array << [{content: " ", height: 5}]
                  _content_table_array << [{content: "<font size='10'><color rgb='000000'>#{x[1].remove_non_ascii.strip}</color></font>", inline_format: true, align: :left, padding: [0, 0, 0, 30], font_style: :others}]
                  _content_table_array << [{content: " "}]
                end

                _desc_table = make_table(_content_table_array, column_widths: [200], cell_style: {border_color: 'FFFFFF'})

                # ======================= Different details ======================= #
                table([
                          # ------ Row 1 -------------------------------------- #
                          [{content: "<font size='36'><color rgb='b20838'>#{Date.today.year.to_s}</color></font>", colspan: 3, height: 60, inline_format: true, padding: [0, 0, 0, 30]}],

                          # ------ Row 2 -------------------------------------- #
                          [
                              {content: "<font size='22'><color rgb='FFFFFF'>#{_product.dump.title.remove_non_ascii.upcase}</color></font>", colspan: 3, height: 80, background_color: 'b20838',
                               align: :right, valign: :center, inline_format: true, padding: [0, 30, 0, 0]}
                          ],

                          # ------ Row 3 -------------------------------------- #
                          [
                              {content: _desc_table, height: 508},

                              # --------------- Column 2 ------------------------- #
                              {image: open(_product.status == 'failed' ? File.basename("#{_product.dump.image.src}.png") : _product.dump.image.src), fit: [204, 508], position: :center, vposition: :center, height: 580, width: 204},

                              # --------------- Column 3 ------------------------- #
                              {content: make_table([
                                                       [{content: " "}],
                                                       [{content: "<font size='13'><color rgb='b20838'><u>TITLE</u></color></font>", inline_format: true, align: :right, padding: [0, 30, 0, 0], font_style: :italic}],
                                                       [{content: " ", height: 5}],
                                                       [{content: "<font size='10'><color rgb='000000'>#{_product.dump.title.remove_non_ascii}</color></font>", inline_format: true, align: :right, padding: [0, 30, 0, 0], font_style: :others}],
                                                       [{content: " "}],
                                                       [{content: "<font size='13'><color rgb='b20838'><u>PRICE</u>    <color></font>", inline_format: true, align: :right, padding: [0, 30, 0, 0], font_style: :italic}],
                                                       [{content: " ", height: 5}],
                                                       [{content: "<font size='10'><color rgb='000000'>$#{_product.dump.variants.first.price}</color></font>", inline_format: true, align: :right, padding: [0, 30, 0, 0], font_style: :others}]
                                                   ],
                                                   column_widths: [200], cell_style: {border_color: 'FFFFFF'}
                              ),
                               padding: [100, 0, 0, 30], height: 508}
                          ],

                          # ------ Row 4 -------------------------------------- #
                          [{content: '', colspan: 3, height: 3, background_color: 'b20838'}],

                          # ------ Row 5 -------------------------------------- #
                          [{content: "<color rgb='b20838'><link href='www.merchant23.com'>www.merchant23.com</link></color>", colspan: 3, height: 30, align: :center,
                            valign: :bottom, inline_format: true}]
                      ],
                      column_widths: [204, 204, 204], position: :center, cell_style: {font_style: :italic, border_color: 'ffffff'}
                )
              end
              puts "====#{_product.id}======Created======"
              _product.update(status: 'Created')
            rescue => e
              puts "=ERROR=====id = #{_product.id}=====#{e.message}==="
              _product.update(status: 'failed')

              image_uri = open(_product.dump.image.src)
              thumb = Magick::Image.read(File.open(image_uri)).first
              thumb.format = 'png'
              thumb.write(File.basename("#{_product.dump.image.src}.png"))
              retry
            end

            # ==================================================================== #
            # ==================================================================== #

          end
          file = File.open(File.join(Dir.pwd, "#{directory_name}/#{product.title}-#{product.id}.pdf"))
          key = File.basename(file)
          obj = AWS_S3.bucket("#{SHOPNAME}").object(key)
          obj.upload_file(file.path, acl: 'public-read')
          url = obj.public_url
          puts url
          metafield = ShopifyAPI::Metafield.new(key: 'pdf_url_s3',
                                                namespace: "headerlabs",
                                                value: url,
                                                value_type: "string")
          product.add_metafield(metafield)
        end
      end
    rescue => e
      puts e.inspect
    end
  end
end