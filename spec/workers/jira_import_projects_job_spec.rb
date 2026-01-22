# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe JiraImportProjectsJob do
  it do
    # OPEN PROJECT OBJECTS
    author = create(:admin)
    jira = create(:jira)
    jira_import = create(
      :jira_import,
      status: "configured",
      jira:,
      projects: ["10001", "10002"],
      author:
    )
    type = create(:type_bug, :default)
    priority = create(:priority, name: "Medium")
    status = create(:status, name: "Backlog")

    # JIRA OBJECTS
    create(
      :jira_status,
      payload: {"id" => "3", "name" => "In Progress", "self" => "http://jira-software.local/rest/api/2/status/3", "iconUrl" => "http://jira-software.local/images/icons/statuses/inprogress.png", "description" => "This issue is being actively worked on at the moment by the assignee.", "statusCategory" => {"id" => 4, "key" => "indeterminate", "name" => "In Progress", "self" => "http://jira-software.local/rest/api/2/statuscategory/4", "colorName" => "inprogress"}},
      jira_status_id: "3",
      jira:,
      jira_import:
    )
    create(
      :jira_status,
      payload: {"id" => "10002", "name" => "Backlog", "self" => "http://jira-software.local/rest/api/2/status/10002", "iconUrl" => "http://jira-software.local/", "description" => "", "statusCategory" => {"id" => 2, "key" => "new", "name" => "To Do", "self" => "http://jira-software.local/rest/api/2/statuscategory/2", "colorName" => "default"}},
      jira_status_id: "10002",
      jira:,
      jira_import:
    )
    create(
      :jira_priority,
      payload: {"id" => "3", "name" => "Medium", "self" => "http://jira-software.local/rest/api/2/priority/3", "iconUrl" => "http://jira-software.local/images/icons/priorities/medium.svg", "description" => "Has the potential to affect progress.", "statusColor" => "#ffab00"},
      jira_priority_id: "3",
      jira:,
      jira_import:
    )
    create(
      :jira_priority,
      payload: {"id" => "10001", "name" => "MAXIMUM123", "self" => "http://jira-software.local/rest/api/2/priority/10001", "iconUrl" => "http://jira-software.local/images/icons/priorities/critical.svg", "description" => "", "statusColor" => "#ffffff"},
      jira_priority_id: "10001",
      jira:,
      jira_import:
    )
    create(
      :jira_issue_type,
      payload:  {"id" => "10002", "name" => "Task", "self" => "http://jira-software.local/rest/api/2/issuetype/10002", "iconUrl" => "http://jira-software.local/secure/viewavatar?size=xsmall&avatarId=10318&avatarType=issuetype", "subtask" => false, "avatarId" => 10318, "description" => "A task that needs to be done."},
      jira_issue_type_id: "10002",
      jira:,
      jira_import:
    )
    create(
      :jira_issue_type,
      payload: {"id" => "10004", "name" => "Bug", "self" => "http://jira-software.local/rest/api/2/issuetype/10004", "iconUrl" => "http://jira-software.local/secure/viewavatar?size=xsmall&avatarId=10303&avatarType=issuetype", "subtask" => false, "avatarId" => 10303, "description" => "A problem which impairs or prevents the functions of the product."},
      jira_issue_type_id: "10004",
      jira:,
      jira_import:
    )

    summary1 = "Test Story created by Pavel"
    summary2 = "Define basic database structure for Jira entities"
    description1 = "Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.\r\n\r\nLorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.\r\n\r\nLorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.\r\n\r\nLorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.\r\n\r\nLorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos."
    description2 = "*About Scrum*\r\n\r\nScrum is an iterative approach to Agile software development. The methodology has been around since the 1980s but was popularised by Jeff Sutherland and Ken Schwaber.\r\n\r\nScrum breaks the development of a product down in to discrete iterations (termed Sprints) that each deliver functionality that could potentially be shipped to users.\r\n\r\nThe Scrum Alliance offers an excellent [introduction to Scrum|http://www.scrumalliance.org/resources/47] that provides an overview of key Scrum concepts, stakeholders, processes and artefacts.\r\n\r\n[~pavel.balashou]"
    jira_projects = [
      create(
        :jira_project,
        jira_project_id: "10002",
        payload: {"id" => "10002", "key" => "PROCESS1", "name" => "PROCESS_MANAGEMENT1", "self" => "http://jira-software.local/rest/api/2/project/10002", "expand" => "description,lead,createdAt,createdBy,lastUpdatedAt,lastUpdatedBy,url,projectKeys", "archived" => false, "avatarUrls" => {"16x16" => "http://jira-software.local/secure/projectavatar?size=xsmall&avatarId=10324", "24x24" => "http://jira-software.local/secure/projectavatar?size=small&avatarId=10324", "32x32" => "http://jira-software.local/secure/projectavatar?size=medium&avatarId=10324", "48x48" => "http://jira-software.local/secure/projectavatar?avatarId=10324"}, "description" => "", "projectKeys" => ["PROCESS1"], "projectTypeKey" => "business"},
        jira:,
        jira_import:,
      ),
      create(
        :jira_project,
        jira_project_id: "10001",
        payload: {"id" => "10001", "key" => "KANBAN1", "name" => "KANBAN1", "self" => "http://jira-software.local/rest/api/2/project/10001", "expand" => "description,lead,createdAt,createdBy,lastUpdatedAt,lastUpdatedBy,url,projectKeys", "archived" => false, "avatarUrls" => {"16x16" => "http://jira-software.local/secure/projectavatar?size=xsmall&avatarId=10324", "24x24" => "http://jira-software.local/secure/projectavatar?size=small&avatarId=10324", "32x32" => "http://jira-software.local/secure/projectavatar?size=medium&avatarId=10324", "48x48" => "http://jira-software.local/secure/projectavatar?avatarId=10324"}, "description" => "", "projectKeys" => ["KANBAN1"], "projectTypeKey" => "software"},
        jira:,
        jira_import:,
      ),
    ]
    create(:jira_issue,
           payload: {"id" => "10023", "key" => "KANBAN1-1", "self" => "http://jira-software.local/rest/api/2/issue/10023", "expand" => "operations,versionedRepresentations,editmeta,changelog,renderedFields", "fields" => {"votes" => {"self" => "http://jira-software.local/rest/api/2/issue/KANBAN1-1/votes", "votes" => 0, "hasVoted" => false}, "labels" => [], "status" => {"id" => "10002", "name" => "Backlog", "self" => "http://jira-software.local/rest/api/2/status/10002", "iconUrl" => "http://jira-software.local/", "description" => "", "statusCategory" => {"id" => 2, "key" => "new", "name" => "To Do", "self" => "http://jira-software.local/rest/api/2/statuscategory/2", "colorName" => "default"}}, "comment" => {"total" => 0, "startAt" => 0, "comments" => [], "maxResults" => 1000}, "created" => "2025-09-27T19:54:09.000+0000", "creator" => {"key" => "JIRAUSER10000", "name" => "pavel.balashou", "self" => "http://jira-software.local/rest/api/2/user?username=pavel.balashou", "active" => true, "timeZone" => "Etc/UTC", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/useravatar?size=xsmall&avatarId=10334", "24x24" => "http://jira-software.local/secure/useravatar?size=small&avatarId=10334", "32x32" => "http://jira-software.local/secure/useravatar?size=medium&avatarId=10334", "48x48" => "http://jira-software.local/secure/useravatar?avatarId=10334"}, "displayName" => "Pavel Balashou", "emailAddress" => "ba1ashpash@gmail.com"}, "duedate" => nil, "project" => {"id" => "10001", "key" => "KANBAN1", "name" => "KANBAN1", "self" => "http://jira-software.local/rest/api/2/project/10001", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/projectavatar?size=xsmall&avatarId=10324", "24x24" => "http://jira-software.local/secure/projectavatar?size=small&avatarId=10324", "32x32" => "http://jira-software.local/secure/projectavatar?size=medium&avatarId=10324", "48x48" => "http://jira-software.local/secure/projectavatar?avatarId=10324"}, "projectTypeKey" => "software"}, "summary" => "Test Story created by Pavel", "updated" => "2025-11-11T11:35:54.000+0000", "watches" => {"self" => "http://jira-software.local/rest/api/2/issue/KANBAN1-1/watchers", "isWatching" => true, "watchCount" => 1}, "worklog" => {"total" => 0, "startAt" => 0, "worklogs" => [], "maxResults" => 20}, "assignee" => {"key" => "JIRAUSER10000", "name" => "pavel.balashou", "self" => "http://jira-software.local/rest/api/2/user?username=pavel.balashou", "active" => true, "timeZone" => "Etc/UTC", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/useravatar?size=xsmall&avatarId=10334", "24x24" => "http://jira-software.local/secure/useravatar?size=small&avatarId=10334", "32x32" => "http://jira-software.local/secure/useravatar?size=medium&avatarId=10334", "48x48" => "http://jira-software.local/secure/useravatar?avatarId=10334"}, "displayName" => "Pavel Balashou", "emailAddress" => "ba1ashpash@gmail.com"}, "priority" => {"id" => "10001", "name" => "MAXIMUM123", "self" => "http://jira-software.local/rest/api/2/priority/10001", "iconUrl" => "http://jira-software.local/images/icons/priorities/critical.svg"}, "progress" => {"total" => 0, "progress" => 0}, "reporter" => {"key" => "JIRAUSER10000", "name" => "pavel.balashou", "self" => "http://jira-software.local/rest/api/2/user?username=pavel.balashou", "active" => true, "timeZone" => "Etc/UTC", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/useravatar?size=xsmall&avatarId=10334", "24x24" => "http://jira-software.local/secure/useravatar?size=small&avatarId=10334", "32x32" => "http://jira-software.local/secure/useravatar?size=medium&avatarId=10334", "48x48" => "http://jira-software.local/secure/useravatar?avatarId=10334"}, "displayName" => "Pavel Balashou", "emailAddress" => "ba1ashpash@gmail.com"}, "subtasks" => [], "versions" => [], "issuetype" => {"id" => "10004", "name" => "Bug", "self" => "http://jira-software.local/rest/api/2/issuetype/10004", "iconUrl" => "http://jira-software.local/secure/viewavatar?size=xsmall&avatarId=10303&avatarType=issuetype", "subtask" => false, "avatarId" => 10303, "description" => "A problem which impairs or prevents the functions of the product."}, "timespent" => nil, "workratio" => -1, "archivedby" => nil, "attachment" => [], "components" => [], "issuelinks" => [], "lastViewed" => "2025-11-11T11:36:14.767+0000", "resolution" => nil, "description" => description1, "environment" => nil, "fixVersions" => [], "archiveddate" => nil, "timeestimate" => nil, "timetracking" => {}, "resolutiondate" => nil, "aggregateprogress" => {"total" => 0, "progress" => 0}, "customfield_10000" => "{summaryBean=com.atlassian.jira.plugin.devstatus.rest.SummaryBean@4cdbd778[summary={pullrequest=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@7ca60471[byInstanceType={},overall=PullRequestOverallBean{stateCount=0, state='OPEN', details=PullRequestOverallDetails{openCount=0, mergedCount=0, declinedCount=0}}], build=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@4bd69234[byInstanceType={},overall=com.atlassian.jira.plugin.devstatus.summary.beans.BuildOverallBean@79f92b3[failedBuildCount=0,successfulBuildCount=0,unknownBuildCount=0,count=0,lastUpdated=<null>,lastUpdatedTimestamp=<null>]], review=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@52cbca94[byInstanceType={},overall=com.atlassian.jira.plugin.devstatus.summary.beans.ReviewsOverallBean@2c628134[dueDate=<null>,overDue=false,state=<null>,stateCount=0,count=0,lastUpdated=<null>,lastUpdatedTimestamp=<null>]], deployment-environment=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@53daf1be[byInstanceType={},overall=com.atlassian.jira.plugin.devstatus.summary.beans.DeploymentOverallBean@28abeb7c[showProjects=false,successfulCount=0,topEnvironments=[],count=0,lastUpdated=<null>,lastUpdatedTimestamp=<null>]], repository=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@24380b97[byInstanceType={},overall=com.atlassian.jira.plugin.devstatus.summary.beans.CommitOverallBean@1c6b5505[count=0,lastUpdated=<null>,lastUpdatedTimestamp=<null>]], branch=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@18381037[byInstanceType={},overall=com.atlassian.jira.plugin.devstatus.summary.beans.BranchOverallBean@6f3ff847[count=0,lastUpdated=<null>,lastUpdatedTimestamp=<null>]]},configErrors=[],errors=[]], devSummaryJson={\"cachedValue\":{\"errors\":[],\"configErrors\":[],\"summary\":{\"pullrequest\":{\"overall\":{\"count\":0,\"lastUpdated\":null,\"stateCount\":0,\"state\":\"OPEN\",\"details\":{\"openCount\":0,\"mergedCount\":0,\"declinedCount\":0,\"total\":0},\"open\":true},\"byInstanceType\":{}},\"build\":{\"overall\":{\"count\":0,\"lastUpdated\":null,\"failedBuildCount\":0,\"successfulBuildCount\":0,\"unknownBuildCount\":0},\"byInstanceType\":{}},\"review\":{\"overall\":{\"count\":0,\"lastUpdated\":null,\"stateCount\":0,\"state\":null,\"dueDate\":null,\"overDue\":false,\"completed\":false},\"byInstanceType\":{}},\"deployment-environment\":{\"overall\":{\"count\":0,\"lastUpdated\":null,\"topEnvironments\":[],\"showProjects\":false,\"successfulCount\":0},\"byInstanceType\":{}},\"repository\":{\"overall\":{\"count\":0,\"lastUpdated\":null},\"byInstanceType\":{}},\"branch\":{\"overall\":{\"count\":0,\"lastUpdated\":null},\"byInstanceType\":{}}}},\"isStale\":false}}", "customfield_10100" => "0|i00053:", "customfield_10101" => nil, "customfield_10102" => nil, "customfield_10107" => nil, "customfield_10108" => nil, "customfield_10109" => nil, "customfield_10110" => nil, "customfield_10111" => nil, "aggregatetimespent" => nil, "timeoriginalestimate" => nil, "aggregatetimeestimate" => nil, "aggregatetimeoriginalestimate" => nil}, "changelog" => {"total" => 3, "startAt" => 0, "histories" => [{"id" => "10300", "items" => [{"to" => "10001", "from" => "3", "field" => "priority", "toString" => "MAXIMUM123", "fieldtype" => "jira", "fromString" => "Medium"}], "author" => {"key" => "JIRAUSER10000", "name" => "pavel.balashou", "self" => "http://jira-software.local/rest/api/2/user?username=pavel.balashou", "active" => true, "timeZone" => "Etc/UTC", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/useravatar?size=xsmall&avatarId=10334", "24x24" => "http://jira-software.local/secure/useravatar?size=small&avatarId=10334", "32x32" => "http://jira-software.local/secure/useravatar?size=medium&avatarId=10334", "48x48" => "http://jira-software.local/secure/useravatar?avatarId=10334"}, "displayName" => "Pavel Balashou", "emailAddress" => "ba1ashpash@gmail.com"}, "created" => "2025-11-11T11:02:34.764+0000"}, {"id" => "10301", "items" => [{"to" => "10004", "from" => "10001", "field" => "issuetype", "toString" => "Bug", "fieldtype" => "jira", "fromString" => "Story"}], "author" => {"key" => "JIRAUSER10000", "name" => "pavel.balashou", "self" => "http://jira-software.local/rest/api/2/user?username=pavel.balashou", "active" => true, "timeZone" => "Etc/UTC", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/useravatar?size=xsmall&avatarId=10334", "24x24" => "http://jira-software.local/secure/useravatar?size=small&avatarId=10334", "32x32" => "http://jira-software.local/secure/useravatar?size=medium&avatarId=10334", "48x48" => "http://jira-software.local/secure/useravatar?avatarId=10334"}, "displayName" => "Pavel Balashou", "emailAddress" => "ba1ashpash@gmail.com"}, "created" => "2025-11-11T11:35:27.844+0000"}, {"id" => "10302", "items" => [{"to" => "JIRAUSER10000", "from" => nil, "field" => "assignee", "toString" => "Pavel Balashou", "fieldtype" => "jira", "fromString" => nil}], "author" => {"key" => "JIRAUSER10000", "name" => "pavel.balashou", "self" => "http://jira-software.local/rest/api/2/user?username=pavel.balashou", "active" => true, "timeZone" => "Etc/UTC", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/useravatar?size=xsmall&avatarId=10334", "24x24" => "http://jira-software.local/secure/useravatar?size=small&avatarId=10334", "32x32" => "http://jira-software.local/secure/useravatar?size=medium&avatarId=10334", "48x48" => "http://jira-software.local/secure/useravatar?avatarId=10334"}, "displayName" => "Pavel Balashou", "emailAddress" => "ba1ashpash@gmail.com"}, "created" => "2025-11-11T11:35:54.887+0000"}], "maxResults" => 3}, "renderedFields" => nil},
           jira_project_id: jira_projects[0].id,
           jira_issue_id: "10023",
           jira:,
           jira_import:,)
    create(:jira_issue,
           payload: {"id" => "10024", "key" => "PROCESS1-1", "self" => "http://jira-software.local/rest/api/2/issue/10024", "expand" => "operations,versionedRepresentations,editmeta,changelog,renderedFields", "fields" => {"votes" => {"self" => "http://jira-software.local/rest/api/2/issue/PROCESS1-1/votes", "votes" => 0, "hasVoted" => false}, "labels" => [], "status" => {"id" => "3", "name" => "In Progress", "self" => "http://jira-software.local/rest/api/2/status/3", "iconUrl" => "http://jira-software.local/images/icons/statuses/inprogress.png", "description" => "This issue is being actively worked on at the moment by the assignee.", "statusCategory" => {"id" => 4, "key" => "indeterminate", "name" => "In Progress", "self" => "http://jira-software.local/rest/api/2/statuscategory/4", "colorName" => "inprogress"}}, "comment" => {"total" => 0, "startAt" => 0, "comments" => [], "maxResults" => 1000}, "created" => "2025-09-27T21:19:06.000+0000", "creator" => {"key" => "JIRAUSER10000", "name" => "pavel.balashou", "self" => "http://jira-software.local/rest/api/2/user?username=pavel.balashou", "active" => true, "timeZone" => "Etc/UTC", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/useravatar?size=xsmall&avatarId=10334", "24x24" => "http://jira-software.local/secure/useravatar?size=small&avatarId=10334", "32x32" => "http://jira-software.local/secure/useravatar?size=medium&avatarId=10334", "48x48" => "http://jira-software.local/secure/useravatar?avatarId=10334"}, "displayName" => "Pavel Balashou", "emailAddress" => "ba1ashpash@gmail.com"}, "duedate" => nil, "project" => {"id" => "10002", "key" => "PROCESS1", "name" => "PROCESS_MANAGEMENT1", "self" => "http://jira-software.local/rest/api/2/project/10002", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/projectavatar?size=xsmall&avatarId=10324", "24x24" => "http://jira-software.local/secure/projectavatar?size=small&avatarId=10324", "32x32" => "http://jira-software.local/secure/projectavatar?size=medium&avatarId=10324", "48x48" => "http://jira-software.local/secure/projectavatar?avatarId=10324"}, "projectTypeKey" => "business"}, "summary" => "Define basic database structure for Jira entities", "updated" => "2025-09-27T21:19:21.000+0000", "watches" => {"self" => "http://jira-software.local/rest/api/2/issue/PROCESS1-1/watchers", "isWatching" => true, "watchCount" => 1}, "worklog" => {"total" => 0, "startAt" => 0, "worklogs" => [], "maxResults" => 20}, "assignee" => {"key" => "JIRAUSER10000", "name" => "pavel.balashou", "self" => "http://jira-software.local/rest/api/2/user?username=pavel.balashou", "active" => true, "timeZone" => "Etc/UTC", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/useravatar?size=xsmall&avatarId=10334", "24x24" => "http://jira-software.local/secure/useravatar?size=small&avatarId=10334", "32x32" => "http://jira-software.local/secure/useravatar?size=medium&avatarId=10334", "48x48" => "http://jira-software.local/secure/useravatar?avatarId=10334"}, "displayName" => "Pavel Balashou", "emailAddress" => "ba1ashpash@gmail.com"}, "priority" => {"id" => "3", "name" => "Medium", "self" => "http://jira-software.local/rest/api/2/priority/3", "iconUrl" => "http://jira-software.local/images/icons/priorities/medium.svg"}, "progress" => {"total" => 0, "progress" => 0}, "reporter" => {"key" => "JIRAUSER10000", "name" => "pavel.balashou", "self" => "http://jira-software.local/rest/api/2/user?username=pavel.balashou", "active" => true, "timeZone" => "Etc/UTC", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/useravatar?size=xsmall&avatarId=10334", "24x24" => "http://jira-software.local/secure/useravatar?size=small&avatarId=10334", "32x32" => "http://jira-software.local/secure/useravatar?size=medium&avatarId=10334", "48x48" => "http://jira-software.local/secure/useravatar?avatarId=10334"}, "displayName" => "Pavel Balashou", "emailAddress" => "ba1ashpash@gmail.com"}, "subtasks" => [], "versions" => [], "issuetype" => {"id" => "10002", "name" => "Task", "self" => "http://jira-software.local/rest/api/2/issuetype/10002", "iconUrl" => "http://jira-software.local/secure/viewavatar?size=xsmall&avatarId=10318&avatarType=issuetype", "subtask" => false, "avatarId" => 10318, "description" => "A task that needs to be done."}, "timespent" => nil, "workratio" => -1, "archivedby" => nil, "attachment" => [], "components" => [], "issuelinks" => [], "lastViewed" => "2025-12-15T10:17:16.017+0000", "resolution" => nil, "description" => description2, "environment" => nil, "fixVersions" => [], "archiveddate" => nil, "timeestimate" => nil, "timetracking" => {}, "resolutiondate" => nil, "aggregateprogress" => {"total" => 0, "progress" => 0}, "customfield_10000" => "{summaryBean=com.atlassian.jira.plugin.devstatus.rest.SummaryBean@3603b315[summary={pullrequest=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@11b1ed03[byInstanceType={},overall=PullRequestOverallBean{stateCount=0, state='OPEN', details=PullRequestOverallDetails{openCount=0, mergedCount=0, declinedCount=0}}], build=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@7add0bd[byInstanceType={},overall=com.atlassian.jira.plugin.devstatus.summary.beans.BuildOverallBean@19eaecbe[failedBuildCount=0,successfulBuildCount=0,unknownBuildCount=0,count=0,lastUpdated=<null>,lastUpdatedTimestamp=<null>]], review=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@2b46900f[byInstanceType={},overall=com.atlassian.jira.plugin.devstatus.summary.beans.ReviewsOverallBean@6db4f412[dueDate=<null>,overDue=false,state=<null>,stateCount=0,count=0,lastUpdated=<null>,lastUpdatedTimestamp=<null>]], deployment-environment=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@475f921[byInstanceType={},overall=com.atlassian.jira.plugin.devstatus.summary.beans.DeploymentOverallBean@4ab46a0d[showProjects=false,successfulCount=0,topEnvironments=[],count=0,lastUpdated=<null>,lastUpdatedTimestamp=<null>]], repository=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@556d4dbc[byInstanceType={},overall=com.atlassian.jira.plugin.devstatus.summary.beans.CommitOverallBean@1f333767[count=0,lastUpdated=<null>,lastUpdatedTimestamp=<null>]], branch=com.atlassian.jira.plugin.devstatus.rest.SummaryItemBean@34247951[byInstanceType={},overall=com.atlassian.jira.plugin.devstatus.summary.beans.BranchOverallBean@5d2989da[count=0,lastUpdated=<null>,lastUpdatedTimestamp=<null>]]},configErrors=[],errors=[]], devSummaryJson={\"cachedValue\":{\"errors\":[],\"configErrors\":[],\"summary\":{\"pullrequest\":{\"overall\":{\"count\":0,\"lastUpdated\":null,\"stateCount\":0,\"state\":\"OPEN\",\"details\":{\"openCount\":0,\"mergedCount\":0,\"declinedCount\":0,\"total\":0},\"open\":true},\"byInstanceType\":{}},\"build\":{\"overall\":{\"count\":0,\"lastUpdated\":null,\"failedBuildCount\":0,\"successfulBuildCount\":0,\"unknownBuildCount\":0},\"byInstanceType\":{}},\"review\":{\"overall\":{\"count\":0,\"lastUpdated\":null,\"stateCount\":0,\"state\":null,\"dueDate\":null,\"overDue\":false,\"completed\":false},\"byInstanceType\":{}},\"deployment-environment\":{\"overall\":{\"count\":0,\"lastUpdated\":null,\"topEnvironments\":[],\"showProjects\":false,\"successfulCount\":0},\"byInstanceType\":{}},\"repository\":{\"overall\":{\"count\":0,\"lastUpdated\":null},\"byInstanceType\":{}},\"branch\":{\"overall\":{\"count\":0,\"lastUpdated\":null},\"byInstanceType\":{}}}},\"isStale\":false}}", "customfield_10100" => "0|i0005b:", "customfield_10101" => nil, "customfield_10102" => nil, "customfield_10107" => nil, "customfield_10108" => nil, "customfield_10109" => nil, "customfield_10110" => nil, "customfield_10111" => nil, "aggregatetimespent" => nil, "timeoriginalestimate" => nil, "aggregatetimeestimate" => nil, "aggregatetimeoriginalestimate" => nil}, "changelog" => {"total" => 1, "startAt" => 0, "histories" => [{"id" => "10027", "items" => [{"to" => "3", "from" => "1", "field" => "status", "toString" => "In Progress", "fieldtype" => "jira", "fromString" => "Open"}], "author" => {"key" => "JIRAUSER10000", "name" => "pavel.balashou", "self" => "http://jira-software.local/rest/api/2/user?username=pavel.balashou", "active" => true, "timeZone" => "Etc/UTC", "avatarUrls" => {"16x16" => "http://jira-software.local/secure/useravatar?size=xsmall&avatarId=10334", "24x24" => "http://jira-software.local/secure/useravatar?size=small&avatarId=10334", "32x32" => "http://jira-software.local/secure/useravatar?size=medium&avatarId=10334", "48x48" => "http://jira-software.local/secure/useravatar?avatarId=10334"}, "displayName" => "Pavel Balashou", "emailAddress" => "ba1ashpash@gmail.com"}, "created" => "2025-09-27T21:19:21.128+0000"}], "maxResults" => 1}, "renderedFields" => nil},
           jira_project_id: jira_projects[1].id,
           jira_issue_id: "10024",
           jira:,
           jira_import:,)

    expect(Project.count).to eq(0)
    expect(WorkPackage.count).to eq(0)
    expect(Type.count).to eq(1)
    expect(Status.count).to eq(1)
    expect(IssuePriority.count).to eq(1)
    expect(OpenProjectJiraReference.count).to eq(0)

    described_class.perform_now(jira_import.id)

    expect(Project.count).to eq(2)
    expect(WorkPackage.count).to eq(2)
    expect(Type.count).to eq(2)
    expect(Status.count).to eq(2)
    expect(IssuePriority.count).to eq(2)
    expect(WorkPackage.pluck(:description)).to include(description1, description2)
    expect(WorkPackage.pluck(:subject)).to include(summary1, summary2)
    expect(OpenProjectJiraReference.count).to eq(10)

    JiraRevertJiraImportJob.perform_now(jira_import.id)

    expect(Project.count).to eq(0)
    expect(WorkPackage.count).to eq(0)
    expect(Type.count).to eq(1)
    expect(Status.count).to eq(1)
    expect(IssuePriority.count).to eq(1)
    expect(OpenProjectJiraReference.count).to eq(0)
  end
end
