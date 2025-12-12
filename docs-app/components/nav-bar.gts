import { LinkTo } from '@ember/routing';

<template>
  <nav class="nav-bar">
    <div class="nav-container">
      <LinkTo @route="index" class="nav-logo">
        <h1>📦 Ember Local Storage Decorator</h1>
      </LinkTo>

      <ul class="nav-links">
        <li><LinkTo @route="index">Home</LinkTo></li>
        <li><LinkTo @route="tracked-storage">TrackedStorage</LinkTo></li>
        <li><LinkTo @route="instances">Pre-instantiated</LinkTo></li>
        <li><LinkTo @route="decorators">Decorators</LinkTo></li>
        <li><LinkTo @route="testing">Testing</LinkTo></li>
        <li>
          <a
            href="https://github.com/evoactivity/ember-local-storage-decorator"
            target="_blank"
            rel="noopener noreferrer"
          >
            GitHub
          </a>
        </li>
      </ul>
    </div>
  </nav>
</template>
