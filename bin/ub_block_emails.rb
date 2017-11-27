
  require 'nokogiri'
  require 'pg'
  require 'cgi'
  require 'rest-client'
  require 'net/smtp'
  #require './patron.rb'

  $INST_ARRAY = ['Abraham Baldwin Agricultural College', 'Albany State University', 'Armstrong State University',
                 'Atlanta Metropolitan State College', 'Augusta University', 'Bainbridge State College', 'Clayton State University',
                 'College of Coastal Georgia', 'Columbus State University', 'Dalton State College', 'East Georgia State College',
                 'Fort Valley State University', 'Georgia College', 'Georgia Gwinnett College',
                 'Georgia Highlands College', 'Georgia Southern University', 'Georgia Southwestern State University',
                 'Georgia State University', 'Gordon State College', 'Kennesaw State University', 'Middle Georgia State University',
                 'Savannah State University', 'South Georgia State College', 'University of Georgia','University of North Georgia',
                 'University of West Georgia', 'Valdosta State University']


  def find_linked_inst(linked_code)
    #@linked_code = params['inst_code']
    @linked_institution = Hash.new("Linked Inst")
    @linked_institution = {2932=>"Abraham Baldwin Agricultural College",2933=>"Albany State University", 2934=>"Armstrong State University",
                           2935=>"Atlanta Metropolitan State College", 2948=>"Augusta University", 2936=>"Bainbridge State College", 2937=>"Claton State University",
                           2938=>"College of Coastal Georgia", 2939=>"Columbus State University", 2940=>"Dalton State College", 2942=>"East Georgia State College",
                           2943=>"Fort Valley State University", 2944=>"Georgia College", 2945=>"Georgia Gwinnett College", 2946=>"Georgia Highlands College",
                           2950=>"Georgia Southern University", 2951=>"Georgia Southwestern State University", 2952=>"Georgia State University", 2953=>"Gordon State College",
                           2954=>"Kennesaw State University", 2955=>"Middle Georgia State University", 2956=>"Savannah State University",
                           2957=>"South Georgia State College", 2959=>"University of Georgia", 2960=>"University of North Georgia", 2961=>"University of West Georgia",
                           2962=>"Valdosta State University"}

    @linked_institution[linked_code.to_i]


  end

  def get_report()
    #get the report from analytics api call
    #puts "I went into the get report function"


    #The following commented table details what the headings are and their corresponding 'Column' in the XML file
    #Column0 -> place holder
    #Column1 ->  First Name
    #Column2 -> Last Name
    #Column3 -> Linked from Institution Code
    #Column4 -> Linked from Institution Name <- The patron's Home Institution where they are blocked
    #Column5 -> Primary Identifier
    #Column6 -> User Group <- Should always be "USG GIL Express Patron"
    #Column7 -> Due Date
    #Column8 -> Institution Name <- This is the Institution the patron borrowed the book from
    #Column9 -> Loan Date <- see filters on the analytics report for more details
    #Column10 -> Barcode
    #Column11 -> Loan Status <-Active or Complete

    @url = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/analytics/reports'
    @headers = { :params => {CGI::escape('path') => '/shared/Galileo Network/Reports/UB Blocked Patrons',
                             CGI::escape('limit') => '1000', CGI::escape('apikey') => 'l7xx309e0969c98d42efa50421682ad25e09'}}

    @billing_report_xml = RestClient::Request.execute :method=> 'GET', :url=>@url, :headers => @headers

    @xml_doc = Nokogiri::XML(@billing_report_xml)
    @xml_doc.remove_namespaces!

    @is_finished = @xml_doc.xpath("//IsFinished").text.to_s
    @resume_token = @xml_doc.xpath("//ResumptionToken").text.to_s


    #puts "The report is finished: " + @isFinished
    #puts @resumeToken



    while @is_finished != "true"
      #puts "Went into while statment"
      puts "URL is " + @url
      @headers_redo = { :params => {CGI::escape('token') => @resume_token,
                                    CGI::escape('limit') => '1000', CGI::escape('apikey') => 'l7xx309e0969c98d42efa50421682ad25e09'}}
      @billing_report_xml_redo = RestClient::Request.execute :method=> 'GET', :url=>@url, :headers => @headers_redo

      @xml_doc_redo = Nokogiri::XML(@billing_report_xml_redo)#.search('Row')
      @xml_doc_redo.remove_namespaces!

      @is_finished = @xml_doc_redo.xpath("//IsFinished").text.to_s

      @new_xml_rows = @xml_doc_redo.xpath("//Row")
      @xml_doc.at('rowset').add_child(@new_xml_rows)

      #puts "The report is finished (while loop):" + @isFinished
    end

    @xml_rows = @xml_doc.xpath("//Row")
    #puts @xml_rows
    return @xml_rows


  end

  def generate_emails
   #generates the emails and queries the Contacts table
    #message = <<MESSAGE_END
    #From: A Person <chris.fishburn42@gmail.com>
    #To: Chris Fishburn <cfish27@uga.edu>
    #Subject: SMTP e-mail test

    #This is a test e-mail message.
#MESSAGE_END

    #Net::SMTP.start('post.uga.edu', 587) do |smtp|
      #smtp.send_message message, 'chris.fishburn42@gmail.com', 'cfish27@uga.edu'
    #end
  end

  def update_blocking_table
    #get report and make a Nokgogiri object
    @ub_report_string = get_report()
    #puts @ub_report_string.class
    #puts @ub_report_string
    #@ub_report = @ub_report_string.xpath("//Row")
    @new_patron_blocks = Array.new
    @blocks_to_remove = Array.new

    #loop through the rows, build arrays of new and removed patrons, then update patrons table
    @ub_report_string.each do |row|
      puts row.at_xpath("Column1").text
      @patron_name = row.at_xpath("Column1").text# + " " +row.at_xpath("Column2").text
      @patron_institution = find_linked_inst(row.at_xpath("Column3").text.to_i)
      @patron_primary_identifier = row.at_xpath("Column5").text.to_s

      @patron = Patron.find_by(name: @patron_name, institution_name: @patron_institution, institution_id: @patron_primary_identifier)

      if (@patron.nil?) #Patron in question is on the report but not on the table, add to new patron array
        #@patron_row = [@patron_name, @patron_institution, @patron_primary_identifier]
        @new_patron_blocks.push([@patron_name, @patron_institution, @patron_primary_identifier])
      end


    end #loop of rows

    #loop thru patrons and see if they are on the report

    Patron.each do |patron|
      @on_report =  fasle
      ub_report.each do |row|
        if patron.name == row.at_xpath("Column1").text.to_s + " " +row.at_xpath("Column2").text.to_s &&
            patron.insitution_name == find_linked_inst(row.at_xpath("Column3").text.to_i) &&
            patron.institution_id = row.at_xpath("Column5").text.to_s

          @on_report = true
        end
      end

      #if not found on report, patron is being removed, put on remove_array
      if @on_report == false
        @blocks_to_remove.push([@patron_name, @patron_institution, @patron_primary_identifier])
      end

    end



    #updates the blocking table

  end

 update_blocking_table



