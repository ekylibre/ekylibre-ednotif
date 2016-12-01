# encoding: utf-8
require 'test_helper'

require 'yaml_nomen'

class Ednotif::OutTranscoderTest < ActiveSupport::TestCase

  setup do

    files = Dir.glob(Ednotif.out_transcoding_dir.join('*')) - Dir.glob(Ednotif.out_transcoding_dir.join('*.exception.yml'))
    YamlNomen.load(:outgoing, files)
  end

  test 'convert hash from ekylibre to savon hashed request on a create birth operation example' do

    ekylibre_request = {
        token: 'abc999abc',
        birth_farm: {
            country_code: 'fr',
            farm_number: '75998877'
        },
        animal: {
            country_code: 'fr',
            identification_number: '7599882110'
        },
        sex: 'female',
        race_code: 'bos_taurus_limousine',
        birth_date: Date.parse('2014-02-01'),
        work_number: '2110',
        name: 'TITOUNETTE',
        mother: {
            animal: {
                country_code: 'fr',
                identification_number: '7599881110'
            },
            race_code: 'bos_taurus_limousine'
        },
        father: {
            animal: {
                country_code: 'fr',
                identification_number: '7599880110'
            },
            race_code: 'bos_taurus_limousine'
        },
        passport_request: true
    }

    expected_savon_request = {
        :"sch:JetonAuthentification" => "abc999abc",
        :"sch:ExploitationNaissance" => {:"sch:CodePays" => "FR", :"sch:NumeroExploitation" => "75998877"},
        :"sch:Bovin" => {:"sch:CodePays" => "FR", :"sch:NumeroNational" => "7599882110"},
        :"sch:Sexe" => "F",
        :"sch:TypeRacial" => "34",
        :"sch:DateNaissance" => "2014-02-01",
        :"sch:NumeroTravail" => "2110",
        :"sch:NomBovin" => "TITOUNETTE",
        :"sch:MerePorteuse" => {:"sch:Bovin" => {:"sch:CodePays" => "FR", :"sch:NumeroNational" => "7599881110"}, :"sch:TypeRacial" => "34"},
        :"sch:PereIPG" => {:"sch:Bovin" => {:"sch:CodePays" => "FR", :"sch:NumeroNational" => "7599880110"}, :"sch:TypeRacial" => "34"},
        :"sch:DemandePasseport" => true}

    doc = Ednotif::OutTranscoder.convert ekylibre_request

    assert_equal expected_savon_request, doc

  end
end