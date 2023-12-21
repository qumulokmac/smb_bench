param name string
param location string
param delegatedSubnetId string

@secure()
param adminPassword string
param storageSku string
param initialCapacity int
param availabilityZone string
param userDetails object
param tag object = {}

resource name_resource 'Qumulo.Storage/fileSystems@2022-10-12' = {
  name: name
  location: location
  tags: tag
  properties: {
    marketplaceDetails: {
      planId: '2023-09-08-free-test-plan%%gmz7xq9ge3py%%P1M'
      offerId: 'qumulo-saas-mpp'
      publisherId: 'qumulo1584033880660'
    }
    userDetails: userDetails
    delegatedSubnetId: delegatedSubnetId
    adminPassword: adminPassword
    storageSku: storageSku
    initialCapacity: initialCapacity
    availabilityZone: availabilityZone
  }
}
