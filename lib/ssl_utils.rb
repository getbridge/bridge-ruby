require 'openssl'

class OpenSSL::X509::Certificate
  def ==(other)
    other.respond_to?(:to_pem) && to_pem == other.to_pem
  end

  # A serial *must* be unique for each certificate. Self-signed certificates,
  # and thus root CA certificates, have the same `issuer' as `subject'.
  def top_level?
    serial == serial && issuer.to_s == subject.to_s
  end
  alias_method :root?, :top_level?
  alias_method :self_signed?, :top_level?
end

# Verifies that the peer certificate is a valid chained certificate. That is,
# it's signed by a root CA or a CA signed by a root CA.
#
# This module will also perform hostname verification against the server’s
# certificate, but _only_ if an instance variable called +@hostname+ exists.
module SSLCertificateVerification
  class << self
    # In PEM format.
    #
    # Eg: http://curl.haxx.se/docs/caextract.html
    attr_accessor :ca_cert_file
  end

  def ca_store
    unless @ca_store
      if file = SSLCertificateVerification.ca_cert_file
        @ca_store = OpenSSL::X509::Store.new
        @ca_store.add_file(file)
      else
        fail "you must specify a file with root CA certificates as `SSLCertificateVerification.ca_cert_file'"
      end
    end
    @ca_store
  end

  # It's important that we try to not add a certificate to the store that's
  # already in the store, because OpenSSL::X509::Store will raise an exception.
  def ssl_verify_peer(cert_string)
    cert = OpenSSL::X509::Certificate.new(cert_string)
    # Some servers send the same certificate multiple times. I'm not even joking... (gmail.com)
    return true if cert == @last_seen_cert
    @last_seen_cert = cert

    if ca_store.verify(@last_seen_cert)
      # A server may send the root certifiacte, which we already have and thus
      # should not be added to the store again.
      ca_store.add_cert(@last_seen_cert) unless @last_seen_cert.root?
      true
    else
      fail "unable to verify the server certificate of `#{@hostname}'"
      false
    end
  end

  def ssl_handshake_completed
    if @hostname
      unless OpenSSL::SSL.verify_certificate_identity(@last_seen_cert, @hostname)
        fail "the hostname `HOSTNAME' does not match the server certificate"
      end
    else
      warn "Skipping hostname verification because `@hostname' is not available."
    end
  end
end
