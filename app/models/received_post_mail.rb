# This class wraps a message string and extracts information that is
# needed to store the message as Post in our database.
#
#     mail = ReceivedPostMail.new(message)
# 
#     mail.content
#     mail.sender_email
#     mail.sender_user
#     mail.recipient_groups
#     mail.message_id
#     mail.content_type
#
class ReceivedPostMail < ReceivedMail
  
  def no_duplicates_exist?(group)
    group.posts.where(message_id: self.message_id).count == 0 and
    group.posts.where(subject: possible_duplicate_subjects(group), author_user_id: self.sender_user.try(:id), sent_at: 1.minute.ago..1.second.from_now).count == 0
  end
  
  def possible_duplicate_subjects(group)
    [
      self.subject,                            # Just the same subject
      "[#{group.name}] #{self.subject}",       # [My Group] Subject with brackets
      self.subject.gsub(/\[.*\] (.*)/) { $1 }  # Brackets removed
    ]
  end
  
  def store_as_posts
    store_as_posts_when_authorized
  end
  
  def store_as_posts_when_authorized
    recipient_groups.collect do |group|
      if no_duplicates_exist?(group) || Rails.env.development?
        if Ability.new(self.sender_user).can? :create_post_for, group
          post = Post.new
          if self.sender_by_email
            post.author_user_id = self.sender_user.id
          elsif self.sender_by_name
            post.author_user_id = self.sender_user.id
            post.external_author = self.sender_string
          else
            post.external_author = self.sender_string
          end
          raise 'something is wrong. this group is not a recipient' unless group.in?(self.recipient_groups)
          post.group_id = group.id
          post.sent_at = Time.zone.now
          post.subject = self.subject
          post.text = self.content
          post.content_type = self.content_type
          post.message_id = self.message_id
          post.save
          if self.has_attachments?
          
            # I've copied this from https://github.com/ivaldi/brimir: ticket_mailer.rb
            self.attachments.each do |attachment|
              file = StringIO.new(attachment.decoded)
              # add needed fields for paperclip
              file.class.class_eval { attr_accessor :original_filename, :content_type }
              file.original_filename = attachment.filename
              file.content_type = attachment.mime_type 
              post_attachment = post.attachments.create(file: file)
              post_attachment.save # FIXME do we need this because of paperclip?
            end
          
            # We need to replace the inline-image sources in the message text:
            attachment_counter = 0
            post.text = post.text.gsub(/(<img [^>]* src=)("cid:[^>"]*")([^>]*>)/) do
              attachment_counter += 1
              attachment = post.attachments.find_by_type("image")[attachment_counter - 1]
              image_url = Rails.application.routes.url_helpers.root_url(Rails.application.config.action_mailer.default_url_options) + attachment.file.url
              "#{$1}\"#{image_url}\"#{$3}" # "<img src=...>" from regex
            end
            post.save
          end
          post
        else # unauthorized!
          @unauthorized_groups ||= []
          @unauthorized_groups << group
          Rails.logger.warn "#{self.sender_email} is not authorized to create a post in group #{group.id} (#{group.name}). Did not save message #{self.message_id} as post."
          nil
        end
      else # duplicates exist!
        Rails.logger.warn "Email duplicate found for message #{self.message_id}. Did not save as post!"
        nil
      end
    end - [nil]
  end

end