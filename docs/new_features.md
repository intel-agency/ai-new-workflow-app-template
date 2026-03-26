# New Features

To plan and implment...

## **F1:** Move all server/opencode/orchestraton-related/non-template clone-related code to the `intel-agency/workflow-orchestration-prebuild` container

The the child tremplates can just reference and use the prebuild package without worrying about the server related code. This will also make the codebase cleaner and more modular, separating the disparate converns cleanly and totally. All the funciotrnality and file3s wil be moved into the lowedt layre, the Docker container so that higher layers have access, i.e. the devonctainer layer on top. Then functionality that used to use all the code in the existing template repo can just exec into the devcontainer and use the prebuild container to run the orchestration process, without needing to worry about the underlying code or dependencies. This will also make it easier to maintain and update the orchestration code, as it will be centralized in one place rather than being scattered across multiple templates.


## **F2:** Add a dispatch message case to trigger the orchestration process to find and begin resolving existing open issues with specific labels

Can work them in prioirty order, if > 1 openiussue w/ a target label, then we can pick the one with the oldest creation date to work on first. This will help us to resolve the existing open issues in a more systematic and efficient way, rather than just randomly picking one to work on. It will also help us to ensure that we are addressing the most urgent and important issues first, rather than just working on whatever happens to be at the top of the list.

## **F3:** Remove explicit dependence on Github for event source

Dependencies: **F1** (moving orchestration code to prebuild container)

1. Create REST or webhook interface to the orchestration prompt that can receive event data from any source (e.g., GitHub, GitLab, Jira, etc.)
2. Update the datamodel to not depend exactly on GH event data (we can keep the same conceppt but make it slightly more generic to accomodate other sources)
3. Update the orchestration prompt to use the new generic datamodel
4. Move the devcontainer opencode server to run as a service that we can self-host on my linux server
5. Create GH App that listens listens for events and sned a webhook with the data to the new interface when relevant events occur (e.g., issue labeled with `orchestration:plan-approved`)
