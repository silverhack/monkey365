# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#https://docs.microsoft.com/en-us/previous-versions/office/sharepoint-csom/ee541430(v=office.15)
Enum PrincipalType{
    None = 0
    User = 1
    DistributionList = 2
    SecurityGroup = 4
    SharePointGroup = 8
    All = 15
}
#https://docs.microsoft.com/en-us/previous-versions/office/sharepoint-server/ee540560(v=office.15)
Enum BaseType{
    None = -1
    GenericList = 0
    DocumentLibrary = 1
    Unused = 2
    DiscussionBoard = 3
    Survey = 4
    Issue = 5
}
Enum FileSystemObjectType{
    Invalid = -1
    File = 0
    Folder = 1
    Web = 2
}
#https://docs.microsoft.com/en-us/openspecs/sharepoint_protocols/ms-csomspt/32ed53d1-82d7-4702-962d-1835b031365b?redirectedfrom=MSDN
Enum ChangeRequestStatus{
    Pending = 0
    Approved = 1
    Accepted = 2
    Denied = 3
    Expired = 4
    Revoked = 5
}
#https://docs.microsoft.com/en-us/dotnet/api/microsoft.sharepoint.client.sharinglinkkind?view=sharepoint-csom
Enum SharingLinkKind{
    Uninitialized = 0
    Direct = 1
    OrganizationView = 2
    OrganizationEdit = 3
    AnonymousView = 4
    AnonymousEdit = 5
    Flexible = 6
}
