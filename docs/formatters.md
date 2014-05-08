# Formatters

Adding context to alerts is done by the formatters.  Formatters are where all the fun happens.

## Writing the Formatter

When called, the ``nagios-herald`` invokes various formatting functions on a formatter class
(that you'll write) and falls back on the default formatter class for any methods that your formatter
does not override.  The methods available to be overridden are:

    ack_info
    additional_details
    additional_info
    alert_ack_url
    host_info
    notes
    notification_info
    recipients_email_link
    short_ack_info
    short_state_detail
    state_info

All of these methods are defined in the ``Formatter::Base`` class located at
``lib/nagios-herald/formatters/base.rb``.

See below for an example of content generated using some of the above methods.

<img src="/docs/assets/img/nagios-herald-formatter-content-example.png" style="border:1px solid #a1a1a1;">

To begin writing your own formatter, create a new create a new Ruby file that inherits from ``NagiosHerald::Formatter``.
This file will define the formatter class you intend to write.  The file and class should follow a specific naming convention:

* The class name is camel-cased.
* The class file name is lower-cased and uses underscores between words.

As an example, a formatter used for providing context for disk space checks would have a class name of
``CheckDisk`` and the class file would be named ``check_disk.rb``.  This is a typical Ruby pattern and one
that is enforced in ``nagios-herald`` via code that imports classes based on the class file name.

1. Create your formatter and extend the ``NagiosHerald::Formatter`` class:

```ruby
module NagiosHerald
  module Formatter
    class CheckDisk < NagiosHerald::Formatter
      include NagiosHerald::Logging

      def additional_details
        "nagios-herald makes alerting more bearable."
      end

    end
  end
end
```

2. Override the sections you want to customize.

    You can define the text and/or HTML content in a message by calling the ``add_text`` and ``add_html`` methods
    inside a formatting method:

``ruby
add_text "Something blew up!"
add_html "Something <b>blew</b> up!"
```

    An example of an overridden ``additional_info`` method could be:

```ruby
def additional_info
  section = __method__  # this defines the section key in the formatter's content hash
  hostname  = get_nagios_var("NAGIOS_HOSTNAME")
  add_text(section, "The hostname is #{hostname}")
  add_html(section, "The hostname is <b>#{hostname}</b>")
end
```

3. Optional: Inline static images in the message.

    Call the ``add_attachment`` method and specify the full path to the image file to be attached.
    The mailer will then inline the image in the HTML body of the message.

```ruby
partitions_chart = "/path/to/partition_chart.png"
add_attachment partitions_chart
add_html "<img src='#{partitions_chart}' width='300' alt='partitions_remaining_space' />"
```

4. Optional: Attach documents to the message.

    Call the ``add_attachment`` method and specify the full path to the document to be attached.  **Done**.

        add_attachment "/path/to/file.zip"

