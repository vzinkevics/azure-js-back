# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {
    api_management {
      purge_soft_delete_on_destroy = true
    }
  }
}

resource "azurerm_resource_group" "product_service_rg" {
  location = "northeurope"
  name     = "rg-product-service-sand-ne-003"
}

resource "azurerm_storage_account" "products_service_fa" {
  name     = "stgsangproductsfane889"
  location = "northeurope"

  account_replication_type = "LRS"
  account_tier             = "Standard"
  account_kind             = "StorageV2"

  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_storage_share" "products_service_storage_share" {
  name  = "fa-products-service-share"
  quota = 2

  storage_account_name = azurerm_storage_account.products_service_fa.name
}

resource "azurerm_storage_share" "products_service_storage_share_slot" {
  name  = "fa-products-service-share-slot"
  quota = 2

  storage_account_name = azurerm_storage_account.products_service_fa.name
}

resource "azurerm_service_plan" "product_service_plan" {
  name     = "asp-product-service-sand-ne-001"
  location = "northeurope"

  os_type  = "Windows"
  sku_name = "Y1"

  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_application_insights" "products_service_fa" {
  name             = "appins-fa-products-service-sand-ne-001"
  application_type = "web"
  location         = "northeurope"


  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_windows_function_app" "products_service_new" {
  name     = "fa-products-service-ne-659"
  location = "northeurope"

  service_plan_id     = azurerm_service_plan.product_service_plan.id
  resource_group_name = azurerm_resource_group.product_service_rg.name

  storage_account_name       = azurerm_storage_account.products_service_fa.name
  storage_account_access_key = azurerm_storage_account.products_service_fa.primary_access_key

  functions_extension_version = "~4"
  builtin_logging_enabled     = false

  site_config {
    always_on = false

    application_insights_key               = azurerm_application_insights.products_service_fa.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.products_service_fa.connection_string

    # For production systems set this to false
    use_32_bit_worker = false

    # Enable function invocations from Azure Portal.
    cors {
      allowed_origins = ["https://portal.azure.com"]
    }

    application_stack {
      node_version = "~16"
    }
  }

  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.products_service_fa.primary_connection_string
    WEBSITE_CONTENTSHARE                     = azurerm_storage_share.products_service_storage_share.name
  }

  # The app settings changes cause downtime on the Function App. e.g. with Azure Function App Slots
  # Therefore it is better to ignore those changes and manage app settings separately off the Terraform.
  lifecycle {
    ignore_changes = [
      app_settings,
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"]
    ]
  }
}

resource "azurerm_windows_function_app_slot" "products_service_slot" {
  name     = "non-prod"
  function_app_id      = azurerm_windows_function_app.products_service_new.id
  storage_account_name       = azurerm_storage_account.products_service_fa.name

  functions_extension_version = "~4"
  builtin_logging_enabled     = false

  site_config {
    always_on = false

    application_insights_key               = azurerm_application_insights.products_service_fa.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.products_service_fa.connection_string

    # For production systems set this to false
    use_32_bit_worker = false

    # Enable function invocations from Azure Portal.
    cors {
      allowed_origins = ["https://portal.azure.com"]
    }

    application_stack {
      node_version = "~16"
    }
  }

  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.products_service_fa.primary_connection_string
    WEBSITE_CONTENTSHARE                     = azurerm_storage_share.products_service_storage_share_slot.name
  }

  # The app settings changes cause downtime on the Function App. e.g. with Azure Function App Slots
  # Therefore it is better to ignore those changes and manage app settings separately off the Terraform.
  lifecycle {
    ignore_changes = [
      app_settings,
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"]
    ]
  }
}

resource "azurerm_resource_group" "rg_apim" {
  location = "northeurope"
  name     = "rg-apim-sand-ne-001"
}

resource "azurerm_api_management" "products_service_apim" {
  name                = "products-service-apim"
  location            = azurerm_resource_group.rg_apim.location
  resource_group_name = azurerm_resource_group.rg_apim.name
  publisher_name      = "Vadim"
  publisher_email     = "zinkevicsvadims@gmail.com"
  sku_name = "Consumption_0"
}

resource "azurerm_api_management_api" "products_service_api" {
  name                = "products-service-api"
  api_management_name = azurerm_api_management.products_service_apim.name
  resource_group_name = azurerm_resource_group.rg_apim.name
  revision            = "1"
  display_name        = "Products API"
  protocols           = ["https"]
  path                = "test"
  subscription_required = true
  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }
}

resource "azurerm_api_management_api_operation" "get_products_operation" {
  operation_id        = "get-products"
  api_name            = azurerm_api_management_api.products_service_api.name
  api_management_name = azurerm_api_management.products_service_apim.name
  resource_group_name = azurerm_resource_group.rg_apim.name
  display_name        = "Get Products"
  method              = "GET"
  url_template        = "/api/products"
}

resource "azurerm_api_management_api_operation" "get_product_operation" {
  operation_id        = "get-product"
  api_name            = azurerm_api_management_api.products_service_api.name
  api_management_name = azurerm_api_management.products_service_apim.name
  resource_group_name = azurerm_resource_group.rg_apim.name
  display_name        = "Get Product"
  method              = "GET"
  url_template        = "/api/products/{id}"

  template_parameter {
    name     = "id"
    type     = "string"
    required = true
  }
}

resource "azurerm_api_management_api_operation" "get_total_products_operation" {
  operation_id        = "get-total-products"
  api_name            = azurerm_api_management_api.products_service_api.name
  api_management_name = azurerm_api_management.products_service_apim.name
  resource_group_name = azurerm_resource_group.rg_apim.name
  display_name        = "Get Total Products"
  method              = "GET"
  url_template        = "/api/products/total"
}

resource "azurerm_api_management_api_operation" "create_product_operation" {
  operation_id        = "create-product"
  api_name            = azurerm_api_management_api.products_service_api.name
  api_management_name = azurerm_api_management.products_service_apim.name
  resource_group_name = azurerm_resource_group.rg_apim.name
  display_name        = "Create Product"
  method              = "POST"
  url_template        = "/api/product"
}

data "azurerm_function_app_host_keys" "productsServiceHostKeys" {
  name                = azurerm_windows_function_app.products_service_new.name
  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_api_management_named_value" "productsServiceDefaultKey" {
  name                = "productsServiceDefaultKey"
  resource_group_name = azurerm_resource_group.rg_apim.name
  api_management_name = azurerm_api_management.products_service_apim.name
  display_name        = "funcDcDefaultKey"
  secret              = true
  value               = data.azurerm_function_app_host_keys.productsServiceHostKeys.default_function_key
}

resource "azurerm_api_management_api_policy" "payment_service_api_policy" {
  api_name            = azurerm_api_management_api.products_service_api.name
  api_management_name = azurerm_api_management.products_service_apim.name
  resource_group_name = azurerm_resource_group.rg_apim.name

  xml_content = <<XML
    <policies>
      <inbound>
          <set-backend-service base-url="https://fa-products-service-ne-659.azurewebsites.net" />
          <set-header name="x-functions-key" exists-action="override">
            <value>{{funcDcDefaultKey}}</value>
          </set-header>
          <base/>
          <cors allow-credentials="false">
              <allowed-origins>
                  <origin>*</origin>
              </allowed-origins>
              <allowed-methods>
                  <method>GET</method>
                  <method>POST</method>
              </allowed-methods>
              <allowed-headers>
                  <header>*</header>
              </allowed-headers>
              <expose-headers>
                  <header>*</header>
              </expose-headers>
          </cors>
          <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" downstream-caching-type="private" must-revalidate="true" caching-type="internal" allow-private-response-caching="true">
              <vary-by-header>Accept</vary-by-header>
              <vary-by-header>Accept-Charset</vary-by-header>
          </cache-lookup>
      </inbound>
      <backend>
          <base/>
      </backend>
      <outbound>
          <cache-store duration="20" />
          <base/>
      </outbound>
      <on-error>
          <base/>
      </on-error>
     </policies>
  XML
}

resource "azurerm_cosmosdb_account" "test_app" {
  location            = "northeurope"
  name                = "cos-app-sand-ne-889"
  offer_type          = "Standard"
  resource_group_name = azurerm_resource_group.product_service_rg.name
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Eventual"
  }

  capabilities {
    name = "EnableServerless"
  }

  geo_location {
    failover_priority = 0
    location          = "North Europe"
  }
}

resource "azurerm_cosmosdb_sql_database" "products_app" {
  account_name        = azurerm_cosmosdb_account.test_app.name
  name                = "products-db"
  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_cosmosdb_sql_container" "products" {
  account_name        = azurerm_cosmosdb_account.test_app.name
  database_name       = azurerm_cosmosdb_sql_database.products_app.name
  name                = "products"
  partition_key_path  = "/id"
  resource_group_name = azurerm_resource_group.product_service_rg.name

  # Cosmos DB supports TTL for the records
  default_ttl = -1

  indexing_policy {
    excluded_path {
      path = "/*"
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "stocks" {
  account_name        = azurerm_cosmosdb_account.test_app.name
  database_name       = azurerm_cosmosdb_sql_database.products_app.name
  name                = "stocks"
  partition_key_path  = "/product_id"
  resource_group_name = azurerm_resource_group.product_service_rg.name

  # Cosmos DB supports TTL for the records
  default_ttl = -1

  indexing_policy {
    excluded_path {
      path = "/*"
    }
  }
}
