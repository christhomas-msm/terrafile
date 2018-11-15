require_relative '../spec_helper'

module Terrafile
  RSpec.describe Dependency do
    describe 'class methods' do
      describe '::build_from_terrafile' do
        before do
          modules = {
            'terraform-aws-name1' => {
              'source' => 'git@github.com:org1/repo1',
              'version' => '0.8.0',
            },
            'terraform-aws-name2' => {
              'source' => 'git@github.com:org2/repo2',
              'version' => '004e5791',
            },
          }
          allow(File).to receive(:read).and_return(double)
          allow(YAML).to receive(:safe_load).and_return(modules)
        end

        it 'instantiates a dependency for each module listed in the Terrafile' do
          allow(Dependency).to receive(:new)

          Dependency.build_from_terrafile

          expect(Dependency).to have_received(:new).with(
            name: 'terraform-aws-name1',
            source: 'git@github.com:org1/repo1',
            version: '0.8.0'
          )

          expect(Dependency).to have_received(:new).with(
            name: 'terraform-aws-name2',
            source: 'git@github.com:org2/repo2',
            version: '004e5791'
          )
        end

        it 'returns a list of dependencies' do
          expect(Dependency.build_from_terrafile.size).to eq(2)
        end
      end
    end

    describe 'instance methods' do
      describe '#fetch' do
        let(:dependency) do
          Dependency.new(
            name:    'terraform-of-mine',
            version: '1.2.3',
            source:  'git@github.com:org1/repo1'
          )
        end

        before do
          allow(Dir).to receive(:chdir).and_yield
          allow(Helper).to receive(:clone)
          allow(Helper).to receive(:repo_up_to_date?)
          allow(Helper).to receive(:pull_repo)
        end

        context 'if a sub-directory named for the dependency already exists' do
          before do
            allow(Helper).to receive(:dir_exists?)
              .with('terraform-of-mine').and_return(true)
          end

          it 'does not re-clone the module' do
            dependency.fetch

            expect(Helper).not_to have_received(:clone)
              .with('git@github.com:org1/repo1', 'terraform-aws-name1')
          end

          it 'changes into the sub-directory for that dependency' do
            dependency.fetch

            expect(Dir).to have_received(:chdir).with('terraform-of-mine')
          end

          it 'tests whether the repo is out of date' do
            dependency.fetch

            expect(Helper).to have_received(:repo_up_to_date?).with('1.2.3')
          end

          context 'if the module needs to be updated' do
            before do
              allow(Helper).to receive(:repo_up_to_date?).and_return(false)
            end

            it 'pulls the latest revision down' do
              dependency.fetch

              expect(Helper).to have_received(:pull_repo)
            end
          end

          context 'if the module is up-to-date' do
            before do
              allow(Helper).to receive(:repo_up_to_date?).and_return(true)
            end

            it 'does not attempt to pull fresh revisions' do
              dependency.fetch

              expect(Helper).not_to have_received(:pull_repo)
            end
          end
        end

        context 'if a sub-directory named for the dependency DOES NOT already exists' do
          before do
            allow(Helper).to receive(:dir_exists?)
              .with('terraform-of-mine').and_return(false)
          end

          it 'does clone the module' do
            dependency.fetch

            expect(Helper).to have_received(:clone)
              .with('git@github.com:org1/repo1', 'terraform-of-mine')
          end
        end
      end

      describe '#checkout' do
        let(:dependency) do
          Dependency.new(name: 'terraform-of-mine', version: '1.2.3', source: double)
        end

        before do
          allow(Dir).to receive(:chdir).and_yield
          allow(Helper).to receive(:run!)
        end

        it 'changes to the given dependency\'s directory' do
          dependency.checkout

          expect(Dir).to have_received(:chdir).with('terraform-of-mine')
        end

        it 'checks out the right version of that dependency, suppressing STDOUT' do
          dependency.checkout

          expect(Helper).to have_received(:run!).with('git checkout 1.2.3 1> /dev/null')
        end

        describe 'error handling' do
          context 'when git checkout reports a "reference is not a tree" error' do
            let(:msg) { 'fatal: reference is not a tree:' }
            let(:notice) do
              "The 'version' should be the branch name or tag, " \
                'rather than the SHA.'
            end

            before do
              allow(Kernel).to receive(:puts)
              allow(Helper).to receive(:run!).and_raise(Error, msg)
            end

            it 'logs the suspected use of a SHA rather than a tag or branch name' do
              dependency.checkout
              expect(Kernel).to have_received(:puts).with(/WARN: #{msg}/)
              expect(Kernel).to have_received(:puts).with(/#{notice}/)
            end

            it 'allows execution to continue' do
              expect { dependency.checkout }.not_to raise_error
            end
          end

          context 'when git checkout reports some other error' do
            let(:msg) { 'fatal: some other problem:' }

            before do
              allow(Helper).to receive(:run!).and_raise(Error, msg)
            end

            it 're-raises the Terraform::Error' do
              expect { dependency.checkout }.to raise_error(Error, msg)
            end
          end
        end
      end
    end
  end
end
