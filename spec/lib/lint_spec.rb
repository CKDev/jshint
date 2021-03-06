require 'spec_helper'
require 'jshint'

describe Jshint::Lint do
  let(:file)          { 'foo/bar/baz.js' }
  let(:excluded_file) { 'foo/bar/qux.js' }
  let(:files)         { [file, excluded_file] }
  let(:configuration) { double("Configuration").as_null_object }
  let(:opts)          { MultiJson.dump({ :curly => true, :newcap => true }) }
  let(:globals)       { MultiJson.dump({ :jquery => true, :app => true }) }
  let(:file_paths)    { ['foo/**/*.js'] }
  let(:excluded_files){ [excluded_file] }

  subject do
    allow(Jshint::Configuration).to receive(:new).and_return(configuration)
    described_class.new
  end

  it "should initialize errors to an empty Hash" do
    expect(subject.errors).to be_a Hash
  end

  it "should assing the Configration object to config" do
    expect(subject.config).to eq(configuration)
  end

  it "should respond to get_json" do
    hash = { :hello => 'world' }
    expect(MultiJson).to receive(:dump).with(hash)
    subject.get_json(hash)
  end

  describe "lint" do
    before do
      allow(subject).to receive(:javascript_files).and_return(files)
      allow(subject).to receive(:jshint_options).and_return(opts)
      allow(subject).to receive(:jshint_globals).and_return(globals)
    end

    context "invalid file" do
      before do
        allow(subject).to receive(:get_file_content_as_json).
          and_return(subject.get_json(<<-eos
              var foo = "bar",
                  baz = "qux",
                  bat;

              if (foo == baz) bat = "gorge" // no semicolon and single line
            eos
          ))
        subject.lint
      end

      it "should add two error messages to the errors Hash" do
        expect(subject.errors[file].length).to eq(2)
      end
    end

    context "valid file" do
      before do
        allow(subject).to receive(:get_file_content_as_json).
          and_return(subject.get_json(<<-eos
              var foo = "bar",
                  baz = "qux",
                  bat;

              if (foo == baz) {
                bat = "gorge";
                var x = "foo"; // jshint ignore:line
              }
            eos
          ))
        subject.lint
      end

      it "should retrieve the files content" do
        expect(subject).to receive(:get_file_content_as_json).with(file)
        subject.lint
      end

      it "should add two error messages to the errors Hash" do
        expect(subject.errors[file].length).to eq(0)
      end
    end
  end

  describe 'javascript_files' do

    before do
      allow(subject).to receive(:file_paths).and_return(file_paths)
      allow(subject.config).to receive(:excluded_files).and_return(excluded_files)
      allow(Dir).to receive(:glob).with(anything()).and_yield(file).and_yield(excluded_file)
    end

    it 'should not include excluded files' do
      expect(subject.send(:javascript_files)).to eq([file])
    end
  end
end
