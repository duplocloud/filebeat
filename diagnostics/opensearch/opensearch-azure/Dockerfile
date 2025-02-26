FROM opensearchproject/opensearch:2.11.0

# Install the Azure repository plugin
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch repository-azure

# Copy the keystore creation script
COPY create-keystore.sh /usr/share/opensearch/
RUN chmod +x /usr/share/opensearch/create-keystore.sh

# Copy the entrypoint script
COPY entrypoint.sh /usr/share/opensearch/
RUN chmod +x /usr/share/opensearch/entrypoint.sh

ENTRYPOINT ["/usr/share/opensearch/entrypoint.sh"]
