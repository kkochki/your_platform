# This application can receive emails and interpret them as posts or
# comments. To achieve this, the incoming emails need to be patched
# through to this controller.
#
# 1. Collect all emails in the relevant email namespace, for example
#      using a catch-all email address `*.example.com`. The email
#      server may differ from the app server.
#
# 2. Have all these emails redirected to an address on a server
#      where you have access to the `/etc/aliases`, for example
#      `platform-mailgate@postfix.example.com`.
#
# 3. On this server, e.g. postfix.example.com, add an entry to the
#     `/etc/aliases`:
#
#          # /etc/aliases
#          platform-mailgate: "|/bin/bash /path/to/script https://example-platform.com/incoming_emails"
#
#     In the above entry, `example-platform.com` is the app server,
#     and `/path/to/script` refers to a script on the
#     same server as `/etc/aliases`, which sends the incoming
#     email to the given url via a `POST` request.
#
#     We provide an example script here:
#     https://github.com/fiedl/your_platform/blob/master/script/mailgate
#
#         # /path/to/script
#         exec curl --silent --output /dev/null --data-urlencode message@- $1
#
#     For testing, you can download the script and pipe an example
#     email in:
#
#         # bash
#         cat test-message.eml |/bin/bash /path/to/script https://example-platform.com/incoming_emails
#
#     The app's `/incoming_emails` path is handled by this controller.
#
class IncomingMailsController < ApplicationController

  # POST /incoming_emails
  # Provide the raw message as `message` parameter.
  #
  def create
    params[:message] || raise('No `message` parameter given. Have a look at https://github.com/fiedl/your_platform/blob/master/app/controllers/incoming_emails_controller.rb.')

    @created_objects = IncomingMail.create_and_process params
    render json: @created_objects
  end

end