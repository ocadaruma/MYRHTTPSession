Pod::Spec.new do |s|
  s.name         = "MYRHTTPSession"
  s.version      = "0.0.1"
  s.summary      = "Easy to use HTTP library supports progress block"
  s.homepage     = "https://github.com/ocadaruma/MYRHTTPSession"
  s.license      = "MIT"
  s.author       = "haruki okada"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/ocadaruma/MYRHTTPSession.git", :tag => s.version.to_s }
  s.source_files = "MYRHTTPSession", "MYRHTTPSession/*.{h,m}"
  s.requires_arc = true
end
