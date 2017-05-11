class Product < ApplicationRecord

  serialize :dump

  def grab_heading_and_content(a = body_html)
    xml_doc = Nokogiri::HTML(a)
    current_node = nil
    result_node = {}
    sub_root_elements = xml_doc.xpath("//p")
    sub_root_elements = xml_doc.xpath("//div") if sub_root_elements.blank?
    sub_root_elements.each do |p_element|
      if p_element.at_xpath('.//strong').nil?
        result_node[current_node] << p_element if current_node
      else
        current_node = p_element
        result_node[current_node] ||= []
        result_node[current_node] << p_element if current_node
      end
    end

    return [] if result_node.empty?
    result_node.keys.collect { |x| x.at_xpath('.//strong').text }
    result_node.values.last.first.children.collect { |x| x.to_s if x.is_a?(Nokogiri::XML::Text) }.compact

    result_node.collect do |key, values|
      [key.at_xpath('.//strong').text, values.collect { |value| value.children.collect { |x| x.text.strip unless (x.is_a?(Nokogiri::XML::Element) and x.name == 'strong') }.compact }.flatten.compact.join(' ').strip]
    end
  end
end
