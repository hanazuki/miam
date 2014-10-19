describe 'delete' do
  let(:dsl) do
    <<-RUBY
      user "bob", :path=>"/devloper/" do
        login_profile :password_reset_required=>true

        groups(
          "Admin",
          "SES"
        )

        policy "S3" do
          {"Statement"=>
            [{"Action"=>
               ["s3:Get*",
                "s3:List*"],
              "Effect"=>"Allow",
              "Resource"=>"*"}]}
        end
      end

      user "mary", :path=>"/staff/" do
        policy "S3" do
          {"Statement"=>
            [{"Action"=>
               ["s3:Get*",
                "s3:List*"],
              "Effect"=>"Allow",
              "Resource"=>"*"}]}
        end
      end

      group "Admin", :path=>"/admin/" do
        policy "Admin" do
          {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
        end
      end

      group "SES", :path=>"/ses/" do
        policy "ses-policy" do
          {"Statement"=>
            [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
        end
      end
    RUBY
  end

  let(:expected) do
    {:users=>
      {"bob"=>
        {:path=>"/devloper/",
         :groups=>["Admin", "SES"],
         :policies=>
          {"S3"=>
            {"Statement"=>
              [{"Action"=>["s3:Get*", "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}},
         :login_profile=>{:password_reset_required=>true}},
       "mary"=>
        {:path=>"/staff/",
         :groups=>[],
         :policies=>
          {"S3"=>
            {"Statement"=>
              [{"Action"=>["s3:Get*", "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}}}},
     :groups=>
      {"Admin"=>
        {:path=>"/admin/",
         :policies=>
          {"Admin"=>
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}}},
       "SES"=>
        {:path=>"/ses/",
         :policies=>
          {"ses-policy"=>
            {"Statement"=>
              [{"Effect"=>"Allow",
                "Action"=>"ses:SendRawEmail",
                "Resource"=>"*"}]}}}}}
  end

  before(:each) do
    apply { dsl }
  end

  context 'when delete group' do
    let(:delete_group_dsl) do
      <<-RUBY
        user "bob", :path=>"/devloper/" do
          login_profile :password_reset_required=>true

          groups(
            "Admin"
          )

          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { delete_group_dsl }
      expect(updated).to be_truthy
      expected[:users]["bob"][:groups] = ["Admin"]
      expected[:groups].delete("SES")
      expect(export).to eq expected
    end
  end

  context 'when delete user' do
    let(:delete_user_dsl) do
      <<-RUBY
        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end

        group "SES", :path=>"/ses/" do
          policy "ses-policy" do
            {"Statement"=>
              [{"Effect"=>"Allow", "Action"=>"ses:SendRawEmail", "Resource"=>"*"}]}
          end
        end
      RUBY
    end

    subject { client }

    it do
      updated = apply(subject) { delete_user_dsl }
      expect(updated).to be_truthy
      expected[:users].delete("bob")
      expect(export).to eq expected
    end
  end

  context 'when delete user_and_group' do
    let(:delete_user_and_group_dsl) do
      <<-RUBY
        user "mary", :path=>"/staff/" do
          policy "S3" do
            {"Statement"=>
              [{"Action"=>
                 ["s3:Get*",
                  "s3:List*"],
                "Effect"=>"Allow",
                "Resource"=>"*"}]}
          end
        end

        group "Admin", :path=>"/admin/" do
          policy "Admin" do
            {"Statement"=>[{"Effect"=>"Allow", "Action"=>"*", "Resource"=>"*"}]}
          end
        end
      RUBY
    end

    context 'when apply' do
      subject { client }

      it do
        updated = apply(subject) { delete_user_and_group_dsl }
        expect(updated).to be_truthy
        expected[:users].delete("bob")
        expected[:groups].delete("SES")
        expect(export).to eq expected
      end
    end

    context 'when dry-run' do
      subject { client(dry_run: true) }

      it do
        updated = apply(subject) { delete_user_and_group_dsl }
        expect(updated).to be_falsey
        expect(export).to eq expected
      end
    end
  end
end