pipeline {
  agent { label 'Windows' }
  options { timestamps() }

  environment {
    SITE_NAME   = 'github.ai'
    APP_POOL    = 'github.ai'                // same as site name is fine
    SITE_PATH   = 'C:\\inetpub\\wwwroot\\github.ai'
    BACKUP_ROOT = 'C:\\IISBackups'
    PUBLISH_OUT = 'publish'
    SITE_URL    = 'http://localhost:8085/'   // update if your binding differs
    RETAIN_N    = '5'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Restore & Build') {
      steps {
        powershell '''
          dotnet --info
          dotnet restore
          dotnet build -c Release
        '''
      }
    }

    stage('Publish Artifacts') {
      steps {
        powershell '''
          if (Test-Path "${env:PUBLISH_OUT}") { Remove-Item "${env:PUBLISH_OUT}" -Recurse -Force }
          dotnet publish -c Release -o "${env:PUBLISH_OUT}"
          Write-Host "Publish complete to ${env:PUBLISH_OUT}"
        '''
        archiveArtifacts artifacts: "${env:PUBLISH_OUT}/**", fingerprint: true
      }
    }

    stage('Backup Current IIS Site') {
      steps {
        powershell '''
          ./ci/Backup-IISSite.ps1 -SiteName "${env:SITE_NAME}" -SitePath "${env:SITE_PATH}" -BackupRoot "${env:BACKUP_ROOT}" -Retain ${env:RETAIN_N}
        '''
      }
    }

    stage('Deploy to IIS') {
      steps {
        powershell '''
          ./ci/Deploy-DotNetToIIS.ps1 -SiteName "${env:SITE_NAME}" -AppPoolName "${env:APP_POOL}" -SitePath "${env:SITE_PATH}" -PackagePath "${env:WORKSPACE}\\${env:PUBLISH_OUT}"
        '''
      }
    }

    stage('Smoke Test') {
      steps {
        powershell '''
          ./ci/Smoke-Test.ps1 -Url "${env:SITE_URL}"
        '''
      }
    }
  }

  post {
    unsuccessful {
      powershell '''
        ./ci/Rollback-IIS.ps1 -SiteName "${env:SITE_NAME}" -AppPoolName "${env:APP_POOL}" -SitePath "${env:SITE_PATH}" -BackupRoot "${env:BACKUP_ROOT}"
      '''
    }
  }
}
