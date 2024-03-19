require 'logger'
require 'net/smtp'

# Set up logging
logger = Logger.new('backup.log')

# Constants
BACKUP_DIR = '/root/config_backup'
SMTP_SERVER = 'server1'
SENDER_ADDRESS = 'wrt_routerbot@opennetworks.cz'
RECIPIENTS = ['richard@dubny.cz', 'admin@opennetworks.cz']
DEBIAN_IDENTIFICAITON = `ip a l | grep eth0 | grep 192*`

# Create backup directory if it doesn't exist
Dir.mkdir(BACKUP_DIR) unless Dir.exist?(BACKUP_DIR)

def create_backup
  timestamp = Time.now.strftime('%Y%m%d%H%M%S')
  backup_filename = "#{BACKUP_DIR}/debian_config_backup_#{timestamp}.tar.gz"

  # Create a tar.gz backup of specified directories
  begin
    system("tar czf #{backup_filename} /etc /root /etc/config")
    puts "Backup created: #{backup_filename}"
  rescue StandardError => e
    logger.error("Error creating backup: #{e.message}")
  end
end

def send_email(subject, body)
  msg = <<~EMAIL
    From: <#{SENDER_ADDRESS}>
    To: #{RECIPIENTS.join(', ')}
    Subject: #{subject}
    Date: #{Time.now}

    #{body}
  EMAIL

  begin
    Net::SMTP.start(SMTP_SERVER, 25) do |smtp|
      smtp.send_message(msg, SENDER_ADDRESS, RECIPIENTS)
    end
    puts 'Email alert sent successfully.'
  rescue StandardError => e
    logger.error("Error sending email alert: #{e.message}")
  end
end

def main
  loop do
    create_backup
    sleep(3600)
  rescue StandardError => e
    logger.error("Error during backup loop: #{e}")
    send_email('Error Alert', "Error recorded on #{DEBIAN_IDENTIFICAITON}:\n#{e}")
  end
end

if __FILE__ == $PROGRAM_NAME
  main
end
