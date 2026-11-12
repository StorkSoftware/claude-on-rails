module TwoFactorSetupsHelper
  # The SVG is generated from our own provisioning URI, never user input.
  def two_factor_qr_code(provisioning_uri)
    RQRCode::QRCode.new(provisioning_uri).as_svg(module_size: 4, use_path: true, viewbox: true).html_safe
  end
end
