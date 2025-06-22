//api gateway

resource "aws_apigatewayv2_api" "portfolio" {
  name          = local.name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "portfolio" {
  api_id             = aws_apigatewayv2_api.portfolio.id
  integration_method = "POST"
  integration_type   = "AWS_PROXY"

  integration_uri = aws_lambda_function.portfolio.invoke_arn
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.portfolio.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.portfolio.id}"
}


resource "aws_apigatewayv2_stage" "portfolio" {
  api_id      = aws_apigatewayv2_api.portfolio.id
  name        = "$default"
  auto_deploy = true
}

//custom domain 

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = "api.easternlai.me"

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.issued.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_route53_record" "api" {
  name    = aws_apigatewayv2_domain_name.api.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.easternlai-me.id

  alias {
    evaluate_target_health = true
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
  }
}

//domain mapping

resource "aws_apigatewayv2_api_mapping" "api_easternlai_me" {
  api_id          = aws_apigatewayv2_api.portfolio.id
  domain_name     = aws_apigatewayv2_domain_name.api.domain_name
  stage           = aws_apigatewayv2_stage.portfolio.name
  api_mapping_key = ""
}


resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.portfolio.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.portfolio.execution_arn}/*/*"
}
