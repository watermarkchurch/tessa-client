Tessa::Engine.routes.draw do
  post '/tessa/uploads', to: Tessa::RackUploadProxy
end
